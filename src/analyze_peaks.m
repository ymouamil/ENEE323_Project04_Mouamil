%% Peak Analysis Script - Fixed Version
% This script loads the data automatically - no inputs needed
% Just type: analyze_peaks

clear; close all; clc;

% Check if note.wav exists
if ~exist('note.wav', 'file')
    error('note.wav not found in current directory');
end

% Load the original audio file
[vnote, Fs] = audioread('note.wav');
N = length(vnote);

% Compute FFT
V = fft(vnote);
N2 = floor(N/2);
Vleft = V(1:N2+1);
freq_axis = (0:N2) * Fs / N;

fprintf('\n=== Detailed Peak Analysis ===\n');
fprintf('Signal length: %d samples\n', N);
fprintf('Sampling rate: %d Hz\n', Fs);
fprintf('Frequency resolution: %.2f Hz\n', Fs/N);

% Find peaks
[pks, locs, w, p] = findpeaks(abs(Vleft), freq_axis, ...
    'MinPeakHeight', max(abs(Vleft))/20, ...
    'MinPeakDistance', 50);

fprintf('\nFound %d peaks\n', length(pks));
fprintf('\nPeak #\tFrequency (Hz)\tMagnitude\n');
fprintf('------------------------------------\n');
for i = 1:min(15, length(pks))
    fprintf('%d\t%.2f\t\t%.2f\n', i, locs(i), pks(i));
end

% Find fundamental frequency (lowest peak above 50 Hz)
valid_peaks = find(locs > 50 & locs < 500);
if ~isempty(valid_peaks)
    fundamental_freq = locs(valid_peaks(1));
    fprintf('\n========================================\n');
    fprintf('FUNDAMENTAL FREQUENCY: %.2f Hz\n', fundamental_freq);
    fprintf('========================================\n');
    
    % Determine the note
    notes = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'};
    A4 = 440;
    note_number = round(12 * log2(fundamental_freq / A4)) + 69;
    octave = floor(note_number / 12) - 1;
    note_name = notes{mod(note_number, 12) + 1};
    fprintf('This is note: %s%d\n', note_name, octave);
    
    % Identify harmonics
    fprintf('\nHarmonics detected:\n');
    fprintf('Harmonic\tExpected (Hz)\tActual (Hz)\tDifference\n');
    fprintf('------------------------------------------------\n');
    for h = 1:8
        expected = h * fundamental_freq;
        [~, nearest_idx] = min(abs(locs - expected));
        actual = locs(nearest_idx);
        if abs(actual - expected) < 15
            fprintf('%d\t\t%.2f\t\t%.2f\t\t%.2f\n', h, expected, actual, abs(actual-expected));
        end
    end
end

% Plot with peak annotations
figure('Position', [100, 100, 1200, 600]);
findpeaks(abs(Vleft), freq_axis, ...
    'MinPeakHeight', max(abs(Vleft))/20, ...
    'MinPeakDistance', 50, ...
    'Annotate', 'extents');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Peak Analysis of Musical Note');
xlim([0, 3000]);
grid on;
saveas(gcf, 'peak_analysis_figure.png');

fprintf('\nPeak analysis figure saved as: peak_analysis_figure.png\n');