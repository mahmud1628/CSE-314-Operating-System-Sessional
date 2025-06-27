#include <iostream>
#include <string>
#include <fstream>
#include <pthread.h>
#include <chrono>
#include <random>
#include <unistd.h>

#define NUM_TYPEWRITTING_STATIONS 4
#define NUMBER_OF_INTELLIGENT_STAFFS 2
#define OPERATIVE_LAMBDA 2500 // Poisson distribution lambda for operatives
#define STAFF_LAMBDA 1000 // Poisson distribution lambda for intelligent staff

using namespace std;

ifstream infile;
ofstream outfile;

int N,M,x,y,c;
int operations_completed; // global variable to track number of completed operations
int current_staff_count = 0; // global variable to track number of intelligent staffs

auto start_time = chrono::high_resolution_clock::now();
pthread_mutex_t output_mutex, log_book_lock, staff_count_lock;
pthread_mutex_t station_lock[NUM_TYPEWRITTING_STATIONS];
pthread_barrier_t *unit_barriers;

std::random_device rd;
std::mt19937 generator(rd());

std::poisson_distribution<int> operative_dist(OPERATIVE_LAMBDA);
std::poisson_distribution<int> staff_dist(STAFF_LAMBDA);

void init_locks()
{
    for(int i = 0; i < NUM_TYPEWRITTING_STATIONS; i++)
    {
        pthread_mutex_init(&station_lock[i], nullptr);
    }
    pthread_mutex_init(&output_mutex, nullptr);
    pthread_mutex_init(&log_book_lock, nullptr);
    pthread_mutex_init(&staff_count_lock, nullptr);
}

long long get_elapased_time()
{
    auto end_time = chrono::high_resolution_clock::now();
    auto duration = chrono::duration_cast<chrono::milliseconds>(end_time - start_time);
    return duration.count();
}

void write_output(const string &output)
{
    pthread_mutex_lock(&output_mutex); // Lock the mutex for output
    outfile << output;
    outfile.flush(); // Ensure the output is written immediately
    pthread_mutex_unlock(&output_mutex); // Unlock the mutex after output
}

int get_random_delay_for_operative() {
  return operative_dist(generator);
}

int get_random_delay_for_staff() {
  return staff_dist(generator);
}


void * operative_function(void *arg)
{
    int sleep_time = get_random_delay_for_operative() % 5000 + 1; // Random sleep time between 1 and 1000 ms
    usleep(sleep_time * 1000); // Convert to microseconds for usleep

    int operative_id = *((int *) arg);
    bool is_leader = (operative_id % M == 0);
    int station_id = operative_id % NUM_TYPEWRITTING_STATIONS + 1; // in which typewriting station the operative arrived

    write_output("Operative " + to_string(operative_id) + " arrived at typewriting station " + to_string(station_id) + " at time " + to_string(get_elapased_time()) + "\n");

    pthread_mutex_lock(&station_lock[station_id - 1]); // Lock the typewriting station
    write_output("Operative " + to_string(operative_id) + " started document recreation at time " + to_string(get_elapased_time()) + "\n");
    usleep(x * 1000000); // Simulate document recreation time
    write_output("Operative " + to_string(operative_id) + " finished document recreation at time " + to_string(get_elapased_time()) + "\n");
    pthread_mutex_unlock(&station_lock[station_id - 1]); // Unlock the typewriting station

    int unit_id = (operative_id - 1) / M + 1; // Determine the unit ID based on operative ID, 1 based unit indexing 

    pthread_barrier_wait(&unit_barriers[unit_id - 1]); // Wait for all operatives in the unit to finish

    if(is_leader)
    {
        pthread_mutex_lock(&log_book_lock); // Lock the log book
        operations_completed++; // Increment the number of completed operations
        usleep(y * 1000000); // Simulate log book writing time
        pthread_mutex_unlock(&log_book_lock); // Unlock the log book
        write_output("Unit " + to_string(unit_id) + " has completed document recreation phase at time " + to_string(get_elapased_time()) + " leader is " + to_string(operative_id) + "\n");
    }

    return nullptr;
}

void * staff_function(void * arg)
{
    int staff_id = *((int *) arg);

    while(1)
    {
        int random_time = get_random_delay_for_staff() % 2000 + 1; // Random time between 1 and 5000 ms
        usleep(random_time * 1000); // Convert to microseconds for usleep

        pthread_mutex_lock(&staff_count_lock);
        current_staff_count++;
        if(current_staff_count == 1)
        {
            pthread_mutex_lock(&log_book_lock); // Lock the log book if this is the first staff
        }
        pthread_mutex_unlock(&staff_count_lock); // Unlock the staff count mutex

        write_output("Intelligent staff " + to_string(staff_id) + " began reviewing logbook at time " + to_string(get_elapased_time()) + ". Operations completed = " + to_string(operations_completed) + "\n");

        if(operations_completed == c)
        {
            return nullptr; // Exit if all operations are completed
        }

        pthread_mutex_lock(&staff_count_lock);
        current_staff_count--;
        if(current_staff_count == 0)
        {
            pthread_mutex_unlock(&log_book_lock); // Unlock the log book if this is the last staff
        }
        pthread_mutex_unlock(&staff_count_lock); // Unlock the staff count mutex
    }
    return nullptr;   
}


int main()
{
    string input_file = "in.txt";
    string output_file = "out.txt";
    infile.open(input_file);
    if(!infile.is_open())
    {
        cerr << "Error opening input file: " << input_file << endl;
        return 1;
    }   
    outfile.open(output_file);
    if(!outfile.is_open())
    {
        cerr << "Error opening output file: " << output_file << endl;
        return 1;
    }

    infile >> N >> M;
    infile >> x >> y;

    c = N / M; // number of units

    if(c * M != N)
    {
        outfile << "N must be a multiple of M\n";
        return 0;
    }
    init_locks(); // Initialize mutex locks

    unit_barriers = new pthread_barrier_t[c]; // Create barriers for each unit
    for(int i = 0; i < c; i++)
    {
        pthread_barrier_init(&unit_barriers[i], NULL, M);
    }

    pthread_t operative_threads[N];
    pthread_t staff_threads[NUMBER_OF_INTELLIGENT_STAFFS];

    int operative_ids[N];
    for(int i = 0; i < N; i++)
    {
        operative_ids[i] = i + 1; // Assigning IDs to operatives
    }
    int staff_ids[NUMBER_OF_INTELLIGENT_STAFFS];
    for(int i = 0; i < NUMBER_OF_INTELLIGENT_STAFFS; i++)
    {
        staff_ids[i] = i + 1; // Assigning IDs to intelligent staffs
    }

    start_time = chrono::high_resolution_clock::now(); // Reset start time

    for(int i = 0; i < N; i++)
    {
        pthread_create(&operative_threads[i], NULL, operative_function, (void *) &operative_ids[i]);
    }

    for(int i = 0; i < NUMBER_OF_INTELLIGENT_STAFFS; i++)
    {
        pthread_create(&staff_threads[i], NULL, staff_function, (void *) &staff_ids[i]);
    }

    for(int i = 0; i < N; i++)
    {
        pthread_join(operative_threads[i], NULL);
    }

    for(int i = 0; i < NUMBER_OF_INTELLIGENT_STAFFS; i++)
    {
       // pthread_cancel(staff_threads[i]); // Cancel staff threads as they run indefinitely
        pthread_join(staff_threads[i], NULL);
    }

    return 0;
}