// gcc -o progressbar progressbar.c -lm -lncurses

#include <stdio.h>
#include <unistd.h>
#include <ncurses.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

int getAvailableSpace(){
    FILE *fp;
    char buffer[128];
    int available_space = -1; // Initialize to an invalid value

    fp = popen("df -h . | awk 'NR==2 {print $4}'", "r");
    if (fp == NULL) {
        perror("popen");
        return 1;
    }

    if (fgets(buffer, sizeof(buffer), fp) != NULL) {
        sscanf(buffer, "%dG", &available_space);
    }

    pclose(fp);
    return available_space;
}

void loadingBar() {

    // déclarations
    int valeurInitiale;
    int valeurCourante;
    double pourcentageInverse;
    int pourcentageArrondi;

    valeurInitiale = getAvailableSpace();
    initscr();
    start_color();
    init_pair(1, COLOR_GREEN, COLOR_BLACK);

    printw("\n\n\n\n");
    printw("\t\t\t\t\tEspace disque à effacer : %d GB\n", valeurInitiale);
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
    while(!termine){
        usleep(1000000);
        // recalcul à chaque itération
        valeurCourante = getAvailableSpace();
        pourcentageInverse = (1.0 - (double)valeurCourante / valeurInitiale) * 30.0;
        pourcentageArrondi = (int)floor(pourcentageInverse);
        if(pourcentageArrondi>avancement_progress_bar){
            gap = pourcentageArrondi - avancement_progress_bar;
            for(int i=1;i<=gap;i++){
                printw("#");
                refresh();
                avancement_progress_bar = pourcentageArrondi;
            }
            break;
        }
        if(avancement_progress_bar >= 30){
            termine = true;
            break;
        }
    }
    printw("]");
    attroff(COLOR_PAIR(1));
    printw("\n\n\t\t\t\t\tEffacement terminé !\n");
    getch();
    endwin();
}

int main() {
    loadingBar();
    return 0;
}

