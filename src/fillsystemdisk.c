#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>

#define NUM_THREADS sysconf(_SC_NPROCESSORS_ONLN)
#define CHUNK_SIZE 4096

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
unsigned long long total_bytes_written = 0;
unsigned long long total_disk_size = 0;
int threads_completed = 0;

void *thread_function(void *arg) {
    char filename[20];
    snprintf(filename, sizeof(filename), "thread_file_%ld", (long)arg);

    char full_path[100];
    snprintf(full_path, sizeof(full_path), "./%s", filename);

    char command[150]; // Déclaration de la variable "command"
    snprintf(command, sizeof(command), "dd if=/dev/urandom bs=%d count=1 > %s", CHUNK_SIZE, full_path);

    if (strlen(full_path) >= sizeof(command)) {
        fprintf(stderr, "Path is too long\n");
        pthread_exit(NULL);
    }

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

    printf("Filling disk with random data...\n");

    while (1) {
        usleep(1000000);  // Sleep for 1 second

        pthread_mutex_lock(&mutex);
        double percentage_filled = (double)total_bytes_written / total_disk_size * 100;
        pthread_mutex_unlock(&mutex);

        clear_console_line();
        printf("Progress: %.2f%%", percentage_filled);

        if (threads_completed >= NUM_THREADS) {
            printf("\nAll threads completed. Cleaning up...\n");
            break;
        }
    }

    for (int i = 0; i < NUM_THREADS; ++i) {
        pthread_join(threads[i], NULL);
    }

    for (long i = 0; i < NUM_THREADS; ++i) {
        char filename[20];
        snprintf(filename, sizeof(filename), "thread_file_%ld", i);
        remove(filename);
    }

    return 0;
}
