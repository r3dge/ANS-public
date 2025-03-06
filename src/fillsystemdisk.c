// gcc -o fillsystemdisk fillsystemdisk.c -lm -lncurses -lpthread

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <ncurses.h>
#include <math.h>

#define NUM_THREADS sysconf(_SC_NPROCESSORS_ONLN)
#define CHUNK_SIZE 4096

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

unsigned long long total_disk_size = 0;
int threads_completed = 0;

double getAvailableSpace() {
    FILE *fp;
    char buffer[128];
    double available_space = -1; // Initialiser à une valeur invalide
    char unit[3]; // Pour stocker l'unité (G, M, T, etc.)

    // Exécute la commande pour récupérer l'espace libre
    fp = popen("df -h . | awk 'NR==2 {print $4}'", "r");
    if (fp == NULL) {
        perror("popen");
        return -1; // Retourne une valeur invalide en cas d'erreur
    }

    // Lire la sortie
    if (fgets(buffer, sizeof(buffer), fp) != NULL) {
        if (sscanf(buffer, "%lf%2s", &available_space, unit) == 2) {
            // Convertir en Go si nécessaire
            if (strcmp(unit, "M") == 0) {
                available_space /= 1024; // Convertir Mo -> Go
            } else if (strcmp(unit, "T") == 0) {
                available_space *= 1024; // Convertir To -> Go
            } else if (strcmp(unit, "K") == 0) {
                available_space /= (1024 * 1024); // Convertir Ko -> Go
            }
            // Si unité = G, rien à faire
        }
    }

    pclose(fp);
    return available_space; // Retourne l'espace libre en Go
}

void *thread_function(void *arg) {
    char filename[20];
    snprintf(filename, sizeof(filename), "thread_file_%ld", (long)arg);

    char full_path[100];
    snprintf(full_path, sizeof(full_path), "./%s", filename);

    char command[150]; // Déclaration de la variable "command"
    
    snprintf(command, sizeof(command), "dd if=/dev/zero bs=%d of=%s", CHUNK_SIZE, full_path);
    system(command);

    pthread_mutex_lock(&mutex);
    threads_completed++;
    pthread_mutex_unlock(&mutex);

    pthread_exit(NULL);
}

void clear_console_line() {
    printf("\r\033[K");  // Move to the beginning of the line and clear the line
    fflush(stdout);
}

int main() {
    FILE *disk = fopen("remplissage", "wb");
    if (!disk) {
        perror("fopen");
        return 1;
    }

    double valeurInitiale;
    double valeurCourante;
    double pourcentageInverse;
    int pourcentageArrondi;

    fseek(disk, 0, SEEK_END);
    total_disk_size = ftell(disk);
    fclose(disk);

    pthread_t threads[NUM_THREADS];

    for (long i = 0; i < NUM_THREADS; ++i) {
        if (pthread_create(&threads[i], NULL, thread_function, (void *)i) != 0) {
            perror("pthread_create");
            return 1;
        }
    }

    valeurInitiale = getAvailableSpace();
    initscr();
    start_color();
    init_pair(1, COLOR_GREEN, COLOR_BLACK);

    printw("\n\n\n\n");
    printw("\t\t\t\t\tEspace disque à effacer : %f GB\n", valeurInitiale);
    printw("\n\n");
    printw("\t\t\t\t\tEffacement du disque en cours...\n\n");
    printw("\t\t\t\t\t");
    
    // initialisation de la barre
    attron(COLOR_PAIR(1));
    printw("[");
    for (int i = 0; i < 29; i++)
        printw(" ");

    printw("]");
    refresh();
    printw("\r");
    printw("\t\t\t\t\t");
    printw("[");

    bool termine = false;
    int avancement_progress_bar = 0;
    int gap = 0;

    while (1) {
        usleep(1000000); // 1 seconde
        // recalcul à chaque itération
        valeurCourante = getAvailableSpace();
        //printf("valeur courante : %d", valeurCourante);
        pourcentageInverse = (1.0 - valeurCourante / valeurInitiale) * 30.0;
        pourcentageArrondi = (int)floor(pourcentageInverse);
        if(pourcentageArrondi>avancement_progress_bar){
            gap = pourcentageArrondi - avancement_progress_bar;
            for(int i=1;i<=gap;i++){
                printw("#");
                refresh();
            }
            avancement_progress_bar = pourcentageArrondi;
        }
        if(avancement_progress_bar >= 30){
            termine = true;
            break;
        }
    }

    while (1) {
        if (threads_completed >= NUM_THREADS) {
            printf("\nTous les threads sont terminés. Nettoyage...\n");
            break;
        }
        usleep(1000000);  // Sleep for 1 second
    }

    for (int i = 0; i < NUM_THREADS; ++i) {
        pthread_join(threads[i], NULL);
    }

    for (int i = 0; i < NUM_THREADS; ++i) {
        char filename[32];
        snprintf(filename, sizeof(filename), "thread_file_%d", i);
        remove(filename);
    }
    remove("remplissage");

    endwin();
    return 0;
}