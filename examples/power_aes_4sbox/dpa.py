#!/bin/python3

POWER_DATA_FILE = "power_data.txt"

import random
#for plotting
import matplotlib.pyplot as plt
from collections import Counter

def load_power_data():
    with open(POWER_DATA_FILE, "r") as f:
        #the power data is stored as a list of integers one per line
        #each integer is a power measurement
        #the synch signal is 4 zeros one after the other
        # 1. discard everything before the first synch
        # 2. discard the synch signal
        # 3. discard the last 4 measurements
        # 4. this is one power trace
        # 5. repeat until the end of the file
        # don't record anything before the first synch signal
        traces = []
        trace = []
        sync_count = 0
        done_first_sync = False

        for line in f:
            power = int(line)
            if power == 0:
                sync_count += 1
                if sync_count == 2:
                    sync_count = 0
                    if done_first_sync:
                        traces.append(trace)
                    trace = []
                    done_first_sync = True
            else:
                if sync_count == 0:
                    trace.append(power)

        
        #starting from last trace, check if it has the same length as the very first trace
        #if not, discard it
        while len(traces[-1]) != len(traces[0]) and len(traces) > 1:
            traces.pop()
        
        return traces

def differentiate_power_data(traces):
    #differentiate the power traces
    #this is done by subtracting the previous power measurement from the current one
    #the first power measurement is discarded
    differentiated = []
    for trace in traces:
        diff = []
        for i in range(1, len(trace)):
            diff.append((trace[i] - trace[i-1])*2)
        differentiated.append(diff)
    return differentiated

"""
Test values: ACE1ACE1, 59C359C3, B386B386, 670D670C
"""
def lfsr_32bit(seed, taps, length):
    lfsr = seed
    output = []
    for i in range(length):
        output.append(lfsr)
        new_bit = 0
        for tap in taps:
            new_bit ^= (lfsr >> tap) & 1
        lfsr = (lfsr << 1) | new_bit
        lfsr &= 0xFFFFFFFF
    return output

sbox = [
    0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76,
    0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0, 0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0,
    0xB7, 0xFD, 0x93, 0x26, 0x36, 0x3F, 0xF7, 0xCC, 0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15,
    0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A, 0x07, 0x12, 0x80, 0xE2, 0xEB, 0x27, 0xB2, 0x75,
    0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0, 0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84,
    0x53, 0xD1, 0x00, 0xED, 0x20, 0xFC, 0xB1, 0x5B, 0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF,
    0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85, 0x45, 0xF9, 0x02, 0x7F, 0x50, 0x3C, 0x9F, 0xA8,
    0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5, 0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2,
    0xCD, 0x0C, 0x13, 0xEC, 0x5F, 0x97, 0x44, 0x17, 0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73,
    0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88, 0x46, 0xEE, 0xB8, 0x14, 0xDE, 0x5E, 0x0B, 0xDB,
    0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C, 0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79,
    0xE7, 0xC8, 0x37, 0x6D, 0x8D, 0xD5, 0x4E, 0xA9, 0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08,
    0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6, 0xE8, 0xDD, 0x74, 0x1F, 0x4B, 0xBD, 0x8B, 0x8A,
    0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E, 0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E,
    0xE1, 0xF8, 0x98, 0x11, 0x69, 0xD9, 0x8E, 0x94, 0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF,
    0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68, 0x41, 0x99, 0x2D, 0x0F, 0xB0, 0x54, 0xBB, 0x16
]

sbox_inv = [
    0x52, 0x09, 0x6A, 0xD5, 0x30, 0x36, 0xA5, 0x38, 0xBF, 0x40, 0xA3, 0x9E, 0x81, 0xF3, 0xD7, 0xFB,
    0x7C, 0xE3, 0x39, 0x82, 0x9B, 0x2F, 0xFF, 0x87, 0x34, 0x8E, 0x43, 0x44, 0xC4, 0xDE, 0xE9, 0xCB,
    0x54, 0x7B, 0x94, 0x32, 0xA6, 0xC2, 0x23, 0x3D, 0xEE, 0x4C, 0x95, 0x0B, 0x42, 0xFA, 0xC3, 0x4E,
    0x08, 0x2E, 0xA1, 0x66, 0x28, 0xD9, 0x24, 0xB2, 0x76, 0x5B, 0xA2, 0x49, 0x6D, 0x8B, 0xD1, 0x25,
    0x72, 0xF8, 0xF6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xD4, 0xA4, 0x5C, 0xCC, 0x5D, 0x65, 0xB6, 0x92,
    0x6C, 0x70, 0x48, 0x50, 0xFD, 0xED, 0xB9, 0xDA, 0x5E, 0x15, 0x46, 0x57, 0xA7, 0x8D, 0x9D, 0x84,
    0x90, 0xD8, 0xAB, 0x00, 0x8C, 0xBC, 0xD3, 0x0A, 0xF7, 0xE4, 0x58, 0x05, 0xB8, 0xB3, 0x45, 0x06,
    0xD0, 0x2C, 0x1E, 0x8F, 0xCA, 0x3F, 0x0F, 0x02, 0xC1, 0xAF, 0xBD, 0x03, 0x01, 0x13, 0x8A, 0x6B,
    0x3A, 0x91, 0x11, 0x41, 0x4F, 0x67, 0xDC, 0xEA, 0x97, 0xF2, 0xCF, 0xCE, 0xF0, 0xB4, 0xE6, 0x73,
    0x96, 0xAC, 0x74, 0x22, 0xE7, 0xAD, 0x35, 0x85, 0xE2, 0xF9, 0x37, 0xE8, 0x1C, 0x75, 0xDF, 0x6E,
    0x47, 0xF1, 0x1A, 0x71, 0x1D, 0x29, 0xC5, 0x89, 0x6F, 0xB7, 0x62, 0x0E, 0xAA, 0x18, 0xBE, 0x1B,
    0xFC, 0x56, 0x3E, 0x4B, 0xC6, 0xD2, 0x79, 0x20, 0x9A, 0xDB, 0xC0, 0xFE, 0x78, 0xCD, 0x5A, 0xF4,
    0x1F, 0xDD, 0xA8, 0x33, 0x88, 0x07, 0xC7, 0x31, 0xB1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xEC, 0x5F,
    0x60, 0x51, 0x7F, 0xA9, 0x19, 0xB5, 0x4A, 0x0D, 0x2D, 0xE5, 0x7A, 0x9F, 0x93, 0xC9, 0x9C, 0xEF,
    0xA0, 0xE0, 0x3B, 0x4D, 0xAE, 0x2A, 0xF5, 0xB0, 0xC8, 0xEB, 0xBB, 0x3C, 0x83, 0x53, 0x99, 0x61,
    0x17, 0x2B, 0x04, 0x7E, 0xBA, 0x77, 0xD6, 0x26, 0xE1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0C, 0x7D
]

def aes_sbox(val, dec):
    if dec:
        return sbox_inv[val]
    return sbox[val]    

def dpa_analysis(traces, plaintexts):
    #make sure the number of traces and plaintexts is the same
    if len(traces) != len(plaintexts):
        print("Error: number of traces and plaintexts is different")
        return

    #print first 4 tracecs with their corresponding plaintexts
    for i in range(6):
        #format: Trace <trace number>: <trace plaintext in hex> - <trace values in decimal>
        print("Trace %d: %08X - %s" % (i, plaintexts[i], " ".join(str(x) for x in traces[i])))

    """
    traces_0 = {}
    traces_1 = {}   

    for i in range(len(traces)):
        plaintext = plaintexts[i]
        #get the sbox output, bearing in mind that the sbox is applied to the plaintext XORed with the key
        # (there are 4 sboxes in use)
        sbox_in = (plaintext & 0xFF) ^ 0xDE 
        sbox_out = aes_sbox(sbox_in, True)
        #print("Sbox in: %02X, Sbox out: %02X" % (sbox_in, sbox_out))
        #return
        #look at least significant bit of sbox_out, if it is 0, add the trace to traces 0, otherwise put it in traces 1
        target_average = 0
        for j in range(3):
            target_average += traces[i][j+1]
        target_average /= 3
        
        if sbox_out & (1 << 0) == 0:
            if target_average not in traces_0:
                traces_0[target_average] = 1
            else:
                traces_0[target_average] += 1
        else:
            if target_average not in traces_1:
                traces_1[target_average] = 1
            else:
                traces_1[target_average] += 1

    #sort the traces by numerical key value
    traces_0 = sorted(traces_0.items(), key=lambda x: x[0])
    traces_1 = sorted(traces_1.items(), key=lambda x: x[0])

    #print the traces
    print("Traces 0:")
    for k, v in traces_0:
        print("  Trace %f: %d" % (k, v))
    print("Traces 1:")
    for k, v in traces_1:
        print("  Trace %f: %d" % (k, v))

    #plot the distributions of the traces
    # line graph, with x axis being the different power measurements (keys of the dictionary)
    # and y axis the number of traces that have that power measurement (values of the dictionary)
    plt.plot([x[0] for x in traces_0], [x[1] for x in traces_0], label="Traces 0")
    plt.plot([x[0] for x in traces_1], [x[1] for x in traces_1], label="Traces 1")
    plt.legend()
    plt.show()


    return
    """
    



    bucket_0 = [0, 0, 0, 0]
    bucket_0_cnt = 0
    bucket_1 = [0, 0, 0, 0]
    bucket_1_cnt = 0


    # for i in range(len(traces)):
    #     #odd traces are in bucket 0, even traces are in bucket 1
    #     if i % 2 == 0:
    #         #randomly assign to bucket 0 or 1
    #         choice = random.choice([0, 1])
    #         if choice == 0:
    #             bucket_0_cnt += 1
    #             for j in range(4):
    #                 bucket_0[j] += traces[i][2+j]
    #         else:
    #             bucket_1_cnt += 1
    #             for j in range(4):
    #                 bucket_1[j] += traces[i][2+j]
    #     else:
    #         #do the opposite of the previous choice
    #         if choice == 0:
    #             bucket_1_cnt += 1
    #             for j in range(4):
    #                 bucket_1[j] += traces[i][2+j]
    #         else:
    #             bucket_0_cnt += 1
    #             for j in range(4):
    #                 bucket_0[j] += traces[i][2+j]
    


    # #print the differences between the buckets
    # for i in range(4):
    #     print("Bucket[%d], sum for bucket1: %d, sum for bucket2: %d, diff: %f" % (i, bucket_0[i], bucket_1[i], abs(bucket_0[i] - bucket_1[i])))

    # return



    differences = {} #dictionary to store the differences between the power consumption of the two buckets against a proposed least significant byte of the key

    for proposed_key_byte in range(256):
        bucket_0 = [0, 0, 0, 0]
        bucket_0_cnt = 0
        bucket_1 = [0, 0, 0, 0]
        bucket_1_cnt = 0

        for i in range(len(traces)):
            #get the sbox output, bearing in mind that the sbox is applied to the plaintext XORed with the key
            # (there are 4 sboxes in use)
            sbox_byte = plaintexts[i] & 0xFF
            sbox_out = aes_sbox(sbox_byte ^ proposed_key_byte, True)
            #look at least significant bit of sbox_out, if it is 0, add the trace to bucket 0, otherwise put it in bucket 1
            if sbox_out & (1 << 0) == 0:
                #add elements of trace[i][4:8] to bucket 0
                bucket_0_cnt += 1
                for j in range(3):
                    bucket_0[j] += traces[i][j+1]
            else:
                #add elements of trace[i][4:8] to bucket 1
                bucket_1_cnt += 1
                for j in range(3):
                    bucket_1[j] += traces[i][j+1]


        # #plot the distributions of the buckets
        # # line graph, with x axis being the different power measurements
        # # and y axis the number of traces that have that power measurement

        #1. Get average power consumption for each bucket across all elements (i.e. trace[i][0] for all i)
        bucket_0_avg = [x / bucket_0_cnt for x in bucket_0]
        bucket_1_avg = [x / bucket_1_cnt for x in bucket_1]

        #average the contents of each bucket into a single value
        bucket_0_avg = sum(bucket_0_avg) / len(bucket_0_avg)
        bucket_1_avg = sum(bucket_1_avg) / len(bucket_1_avg)
        
        bucket_diff = bucket_0_avg - bucket_1_avg
        #[bucket_0_avg[i] - bucket_1_avg[i] for i in range(len(bucket_0_avg))]

        #get the average 

        differences[proposed_key_byte] = abs(bucket_diff)
        print("Key byte %02X: %f" % (proposed_key_byte, differences[proposed_key_byte]))
        
       

        # #compute the average power consumption and std deviation for each bucket
        # avg_power_0 = sum(bucket_0_flat) / len(bucket_0_flat)
        # avg_power_1 = sum(bucket_1_flat) / len(bucket_1_flat)

        # stddev_power_0 = (sum((x - avg_power_0) ** 2 for x in bucket_0_flat) / len(bucket_0_flat)) ** 0.5
        # stddev_power_1 = (sum((x - avg_power_1) ** 2 for x in bucket_1_flat) / len(bucket_1_flat)) ** 0.5

        # #print the average power consumption for each bucket
        # print("Bucket 0: avg = %f, stddev = %f" % (avg_power_0, stddev_power_0))
        # print("Bucket 1: avg = %f, stddev = %f" % (avg_power_1, stddev_power_1))

    #sort the differences
    differences = sorted(differences.items(), key=lambda x: x[1], reverse=True)
    print("Top 5:")
    #print the top 5 differences
    for i in range(5):
        print("Key byte %02X: %f" % (differences[i][0], differences[i][1]))


def main():
    traces = load_power_data()
    #traces = differentiate_power_data(raw_traces)
    print("Loaded %d traces" % len(traces))
    
    #make sure all traces have the same length
    for i in range(1, len(traces)):
        if len(traces[i]) != len(traces[0]):
            print("Error: trace %d has length %d, expected %d" % (i, len(traces[i]), len(traces[0])))
            return
    
    #print the length of the traces
    print("Trace length: %d" % len(traces[0]))

    plaintexts = lfsr_32bit(0xACE1ACE1, [31, 21, 1, 0], len(traces)+1)
    #drop first value
    plaintexts = plaintexts[1:]

    dpa_analysis(traces, plaintexts)


if __name__ == "__main__":
    main()
