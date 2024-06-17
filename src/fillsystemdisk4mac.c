// gcc -o fillsystemdisk fillsystemdisk.c -lm -lncurses

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ncurses.h>
#include <math.h>
#include <errno.h> // Pour gérer les erreurs système

#define CHUNK_SIZE 4096

unsigned long long total_disk_size = 0;

int getAvailableSpace() {
    FILE *fp;
    char buffer[128];
    int available_space = -1; // Initialise à une valeur invalide

    // Utilise la commande df pour obtenir l'espace disponible en Go
    fp = popen("df -h . | awk 'NR==2 {print $4}'", "r");
    if (fp == NULL) {
        perror("popen");
        return -1;
    }

    if (fgets(buffer, sizeof(buffer), fp) != NULL) {
        sscanf(buffer, "%dG", &available_space);
    }

    pclose(fp);
    return available_space;
}

int write_to_file() {
    char filename[] = "remplissage";

    char command[150]; // Déclaration de la variable "command"
    snprintf(command, sizeof(command), "dd if=/dev/zero bs=%d of=%s", CHUNK_SIZE, filename);

    int result = system(command); // Exécution de la commande
    if (result != 0) {
        // Vérifier si l'erreur est due à "No space left on device"
        if (errno == ENOSPC) {
            printf("Le disque est plein. Arrêt du programme.\n");
        } else {
            fprintf(stderr, "Error: Command execution failed for file %s\n", filename);
        }
        return 0;
    }
    return 1;
}

void clear_console_line() {
    printf("\r\033[K");  // Déplace au début de la ligne et efface la ligne
    fflush(stdout);
}

int main() {
    int valeurInitiale;
    int valeurCourante;
    double pourcentageInverse;
    int pourcentageArrondi;

    valeurInitiale = getAvailableSpace();
    if (valeurInitiale < 0) {
        fprintf(stderr, "Error: Failed to get available disk space\n");
        return 1;
    }

    initscr();
    start_color();
    init_pair(1, COLOR_GREEN, COLOR_BLACK);

    printw("\n\n\n\n");
    printw("\t\t\t\t\tEspace disque à effacer : %d GB\n", valeurInitiale);
    printw("\n\n");
    printw("\t\t\t\t\tEffacement du disque en cours...\n\n");
    printw("\t\t\t\t\t");

    // Initialisation de la barre de progression
    attron(COLOR_PAIR(1));
    printw("[");
    for (int i = 0; i < 29; i++)
        printw(" ");

    printw("]");
    refresh();
    printw("\r");
    printw("\t\t\t\t\t");
    printw("[");

    int avancement_progress_bar = 0;
    int gap = 0;

    // Écriture séquentielle dans un seul fichier et mise à jour de la barre de progression
    while (write_to_file() == 1) {

        usleep(1000000); // 1 seconde
        valeurCourante = getAvailableSpace();
        if (valeurCourante < 0) {
            fprintf(stderr, "Error: Failed to get available disk space\n");
            break;
        }
        pourcentageInverse = (1.0 - (double)valeurCourante / valeurInitiale) * 30.0;
        pourcentageArrondi = (int)floor(pourcentageInverse);
        if (pourcentageArrondi > avancement_progress_bar) {
            gap = pourcentageArrondi - avancement_progress_bar;
            for (int j = 1; j <= gap; j++) {
                printw("#");
                refresh();
            }
            avancement_progress_bar = pourcentageArrondi;
        }
        if (avancement_progress_bar >= 30) {
            break; // Arrêter si la barre de progression est complète
        }
    }

    // Suppression du fichier temporaire
    remove("remplissage");

    endwin();
    return 0;
}

