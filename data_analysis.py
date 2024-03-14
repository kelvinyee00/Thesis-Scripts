import mdfreader
import numpy as np
import matplotlib.pyplot as plt 
mdf_file1 = "HiLMode_noERT.mdf" #reference
mdf_file2 = "HiLMode_ERT.mdf" #new data

def load_mdf(file):
    mdf = mdfreader.Mdf(file,convert_after_read=False)
    data = mdf.get_channel_data('TimerAccuracy')
    return data

def analysis(data):
    sample_amount = len(data)
    print("Sampling amount: ", sample_amount)
    maxdelay= max(data)
    print("Maximum real-time deviation: ", maxdelay/1000000, 'ms')
    mindelay= min(data)
    print("Minimum real-time deviation: ", mindelay/1000000, 'ms')
    average = sum(abs(data))/sample_amount
    print("Average real-time deviation: ", average/1000000, 'ms')

    total_count= 0
    counter=0
    for item in data:
        absvalue=abs(item)
        if absvalue >= 1000000:
            total_count = absvalue+total_count
            counter = counter + 1
    print('Occurence of more than absolute 1 ms is', counter, " out of ", sample_amount)
    rate=counter/sample_amount
    print(f"Occurence rate: {rate} %")
    return [maxdelay,mindelay,average,counter,rate]

def improvements(valuelist1,valuelist2):
    for i in range(len(valuelist1)):
        if abs(valuelist1[i]) > abs(valuelist2[i]):

            compare = (abs(valuelist1[i]) - abs(valuelist2[i]))/abs(valuelist2[i])*100
            print(f"Performance Increment of {compare} %")

        if abs(valuelist1[i]) <= abs(valuelist2[i]):

            compare = (abs(valuelist2[i]) - abs(valuelist1[i]))/abs(valuelist2[i])*100
            print(f"Performance Decrement of {compare} %")

def plotgraph(jitter_values):
    percentages=[]
    for x in jitter_values:
        percentage = x/1000000*100
        percentages.append(abs(percentage))

    jitter = [abs(x/1000000) for x in jitter_values] 

    plt.scatter(percentages, jitter)
    plt.axvline(x=100, color='r', linestyle='-')  
    plt.xlabel('Real-Time 1 ms Threshold (%)')  
    plt.ylabel('Jitter (ms)')  
    plt.grid(True)
    plt.title('Validation of Jitter Delay')  
    plt.show() 

    # create a histogram plot with percentages on the x-axis  
    # x_ticks = np.arange(0, 1.1*threshold, threshold/10)  
    # plt.bar(x_ticks[:-1], percentages, width=threshold/10, align='edge')  
    # plt.axvline(x=threshold, color='r', linestyle='-')  
    # plt.xlabel('Percentage of Jitter Values')  
    # plt.ylabel('Frequency')  
    # plt.title('Distribution of Jitter Values')  
    # plt.show() 

    # # create a scatter plot  
    # plt.scatter(range(len(jitter_values)), jitter_values)  
    # plt.axhline(y=0.001, color='r', linestyle='-')  
    # plt.xlabel('Measurement Number')  
    # plt.ylabel('Jitter')  
    # plt.title('Validation of Jitter Delay')  
    # plt.show()  

def main():
    data_list = []
    data_list1 = load_mdf(mdf_file1)
    data_list2 = load_mdf(mdf_file2)
    parameterlist1 = analysis(data_list1)
    parameterlist2 = analysis(data_list2)
    improvements(parameterlist1,parameterlist2)
    #plotgraph(data_list)

if __name__ == "__main__":
    main()
