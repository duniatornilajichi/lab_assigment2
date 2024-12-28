import file_parser as fp
import matplotlib.pyplot as plt
import numpy as np

data_Q15 = fp.reads('out.pcm')
data = [x / (2**15) for x in data_Q15]

##############################################################################
# Input signal creation
##############################################################################
fs = 8000  # Sampling frequency
freqs = [1000, 2000,3000]  # Frequencies to filter out

t = np.arange(0, fs) / fs  # Time vector
amplitude = 0.5  # Amplitude of input signal

# Create input signal
signal = amplitude * np.concatenate(
    ((np.sin(2 * np.pi * freqs[0] * t), np.sin(2 * np.pi * freqs[1] * t), (np.sin(2 * np.pi * freqs[2] * t)))))
N = len(signal)  # Number of samples in signal

# Add noise to input signal
stdev = 0.05
noise = np.random.normal(0, stdev, N)  # Noise vector
signal = signal + noise  # Noisy signal

##############################################################################
# Simulation of adaptive notch filter (ANF) with fixed rho
##############################################################################

# Initializations
e = np.zeros(N)  # ANF output signal vector
s = np.zeros(3)  # ANF state vector
a = np.zeros(N)  # ANF coefficient vector (for debugging only)
rho = np.zeros(N)  # ANF pole radius

a_i = 1  # initialization of ANF parameter
rho_i = 0.8  # start rho
rho_end  = 0.88
lamb = 0.99 #lamba
mu = 2 * 100 / (2 ** 15)  # 2 * mu

print(mu)
# Simulation loop (iterations over time)
for i in range(N):
    rho_i = lamb * rho_i + (1 - lamb) * rho_end
    rho[i] = rho_i
    s[2] = s[1]
    s[1] = s[0]
    s[0] = signal[i] + rho[i] * a_i * s[1] - (rho[i] ** 2) * s[2]
    e[i] = s[0] - a_i * s[1] + s[2]
    a_i = a_i + 2 * mu * s[1] * e[i]
    a[i] = a_i

# Plot results
plt.figure()
plt.plot(data)
plt.title('')
plt.xlabel('Sample')
plt.ylabel('Amplitude')
plt.show()

plt.figure()
plt.plot(e)
plt.title('Second order python ANF with var rho')
plt.xlabel('Sample')
plt.ylabel('Amplitude')
plt.show()

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import spectrogram

fs = 8000
# Convert data and signal to NumPy arrays
data = np.array(data)
signal = np.array(signal)

##############################################################################
# Function to plot spectrogram
##############################################################################
def plot_spectrogram(ax, signal, fs, title):
    f, t, Sxx = spectrogram(signal, fs, nperseg=256)
    ax.pcolormesh(t, f, 10 * np.log10(Sxx), shading='gouraud')
    ax.set_ylabel('Frequency [Hz]')
    ax.set_xlabel('Time [s]')
    ax.set_title(title)
    ax.colorbar = plt.colorbar(ax.pcolormesh(t, f, 10 * np.log10(Sxx), shading='gouraud'), ax=ax)
    ax.colorbar.set_label('Power [dB]')

##############################################################################
# Plotting
##############################################################################
plt.figure(figsize=(12, 8))

# Input signal spectrogram
ax1 = plt.subplot(2, 1, 1)
plot_spectrogram(ax1, signal, fs, "Input Signal Spectrogram")

# Filtered signal spectrogram
ax2 = plt.subplot(2, 1, 2)
plot_spectrogram(ax2, data, fs, "C Filtered Signal Spectrogram")

# Adjust layout and display the plots
plt.tight_layout()
plt.show()