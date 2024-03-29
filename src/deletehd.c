// compilation : gcc -o deletehd deletehd.c -pthread
// exécution : ./deletehd -d /dev/sda

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>
#include <pthread.h>
#include <time.h>

typedef struct {
    int thread_id;
    const char *destination;
    long long start;
    long long end;
    long long disk_size;
    long long total_written;
} ThreadInfo;

void print_progress(long long current, long long total) {
    float progress = (float)current / total * 100.0;
    printf("\rProgress: %.2f%%", progress);
    fflush(stdout);
}

void *dd_thread(void *arg) {
    ThreadInfo *info = (ThreadInfo *)arg;
    char command[256];
    snprintf(command, sizeof(command), "dd if=/dev/urandom of=%s bs=4096 seek=%lld count=%lld", info->destination, info->start / 4096, (info->end - info->start) / 4096);
    int ret = system(command);
    if (ret != 0) {
        perror("Erreur lors de l'exécution de dd");
        exit(EXIT_FAILURE);
    }

    // Mettre à jour la progression globale
    info->total_written += (info->end - info->start);

    pthread_exit(NULL);
}

int main(int argc, char *argv[]) {
    int opt;
    const char *destination = NULL;

    // Analyser les options de ligne de commande avec getopt
    while ((opt = getopt(argc, argv, "d:")) != -1) {
        switch (opt) {
            case 'd':
                destination = optarg;
                break;
            default:
                fprintf(stderr, "Utilisation : %s -d <chemin_vers_peripherique>\n", argv[0]);
                exit(EXIT_FAILURE);
        }
    }

    // Vérifier si l'option -d a été spécifiée correctement
    if (destination == NULL) {
        fprintf(stderr, "Le chemin vers le périphérique de destination (-d) doit être spécifié.\n");
        exit(EXIT_FAILURE);
    }

    // Obtenir le nombre de cœurs de processeur
    int num_cores = sysconf(_SC_NPROCESSORS_ONLN);

    // Obtenir la taille du disque cible
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "blockdev --getsize64 %s", destination);
    FILE* fp = popen(cmd, "r");
    long long disk_size;
    fscanf(fp, "%lld", &disk_size);
    pclose(fp);

    // Calculer la taille de bloc pour remplir chaque cœur
    long long block_size = disk_size / num_cores;

    // Créer les threads pour remplir l'espace libre avec dd
    pthread_t threads[num_cores];
    ThreadInfo thread_info[num_cores];

    for (int i = 0; i < num_cores; i++) {
        thread_info[i].thread_id = i;
        thread_info[i].destination = destination;
        thread_info[i].start = i * block_size;
        thread_info[i].end = (i == num_cores - 1) ? disk_size : (i + 1) * block_size;
        thread_info[i].disk_size = disk_size;
        thread_info[i].total_written = 0;

        int rc = pthread_create(&threads[i], NULL, dd_thread, (void *)&thread_info[i]);
        if (rc) {
            perror("Erreur lors de la création du thread");
            exit(EXIT_FAILURE);
        }
    }

    // Enregistrer le temps de début d'exécution
    time_t start_time = time(NULL);

    // Attendre la fin de tous les threads et mettre à jour la barre de progression toutes les 10 secondes
    while (1) {
        int all_threads_finished = 1;
        for (int i = 0; i < num_cores; i++) {
            void *thread_retval;
            int rc = pthread_join(threads[i], &thread_retval);
            if (rc) {
                perror("Erreur lors de l'attente du thread");
                exit(EXIT_FAILURE);
            }

            if (thread_retval != NULL) {
                all_threads_finished = 0;
            }
        }

        if (all_threads_finished) {
            break;
        }

        sleep(10); // Mettre à jour la barre de progression toutes les 10 secondes
        long long total_written = 0;
        for (int i = 0; i < num_cores; i++) {
            total_written += thread_info[i].total_written;
        }
        print_progress(total_written, disk_size);
    }

    printf("\nTerminé.\n");

    // Enregistrer le temps de fin d'exécution
    time_t end_time = time(NULL);

    // Calculer la durée d'exécution
    time_t execution_time = end_time - start_time;
    printf("Durée d'exécution : %ld:%02ld:%02ld\n", execution_time / 3600, (execution_time % 3600) / 60, execution_time % 60);

    return 0;
}
