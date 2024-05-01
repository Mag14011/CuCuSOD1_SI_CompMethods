import math
import numpy as np
import matplotlib.pyplot as plt 

#Constants ===============================
n = 1 #Hill Coefficient 
#=========================================

#f = open(input("Enter File name: "))

f = open("ComparativeResult.txt", "r")

HighpH = 12; LowpH = 0
Increment = 0.1; Divisions = int((12/0.1))

idx = 0
pH = [0]*Divisions
sum_Zox = [0]*Divisions
sum_Zred = [0]*Divisions
deltaZ = [0]*Divisions

for scale in np.linspace(LowpH, HighpH, Divisions):
    pH[idx] = scale
    sum_Zox[idx]  =   3 
    sum_Zred[idx] =   2

    for line in f.readlines():
        fields  = line.split()
#       resid   = int(fields[0])
        resname = str(fields[1])
        pKaox   = float(fields[2])
        pKared  = float(fields[3])

        frac_prot_ox  = 1/(1 + math.exp(n * math.log(10) * (scale - pKaox)))
        frac_prot_red = 1/(1 + math.exp(n * math.log(10) * (scale - pKared)))
#       print(f"{scale} {resname} {pKaox} {frac_prot_ox} {pKared} {frac_prot_red}")

        if (resname == "AS4") or (resname == "ASP") or (resname == "GL4") or (resname == "GLU") or (resname == "TYR") or (resname == "PRN"):
            Zox  = (-1 * (1 - frac_prot_ox))
            Zred = (-1 * (1 - frac_prot_red))
            sum_Zox[idx]  += Zox
            sum_Zred[idx] += Zred
        elif (resname == "LYS") or (resname == "HIP") or (resname == "HIS"):
            Zox  = (1 * frac_prot_ox)
            Zred = (1 * frac_prot_red)
            sum_Zox[idx]  += Zox
            sum_Zred[idx] += Zred
        else:
            print("Unidentified Residue:", resname)

    deltaZ[idx] = (sum_Zred[idx] - sum_Zox[idx]) 

    if (scale == LowpH):
        print("%.1f \t %.2f \t %.2f \t %.2f" %(scale, sum_Zox[idx], sum_Zred[idx], deltaZ[idx]), file=open("ChargeRegResult.txt", 'w'))
    else:
        print("%.1f \t %.2f \t %.2f \t %.2f" %(scale, sum_Zox[idx], sum_Zred[idx], deltaZ[idx]), file=open("ChargeRegResult.txt", 'a'))
#   print("=============================================================================")
    idx+=1
    f.seek(0)

#x = pH
#y = deltaZ
#plt.xlim(4.00,8.50)
#plt.ylim(-0.75,-0.25)
#plt.plot(x, y, color='green', linestyle='solid', linewidth = 3) 
#plt.xlabel('pH') 
#plt.ylabel('Delta Z') 
#plt.title('Delta Z vs. pH')
#plt.show() 
