%% ENEE323 Project 04 - Musical Note Analysis
% Student: Mouamil
% UID: 119873526
% Note: Audio playback is commented out for browser compatibility
%       Uncomment soundsc() calls if running on desktop MATLAB

clear all; close all; clc;

%% Load the original audio file
[vnote, Fs] = audioread('note.wav');
N = length(vnote);

fprintf('Original audio loaded. Sampling rate: %d Hz\n', Fs);
fprintf('Signal length: %d samples\n', N);
fprintf('Audio duration: %.2f seconds\n', N/Fs);

% Optional: Playback (uncomment for desktop MATLAB)
% soundsc(vnote, Fs);
% pause(length(vnote)/Fs + 0.5);

%% Problem (i) - Compute DFT and find fundamental frequency
fprintf('\n=== Problem (i) ===\n');

% Compute DFT
V = fft(vnote);
N2 = floor(N/2);
Vleft = V(1:N2+1);

% Frequency axis
freq_axis = (0:N2) * Fs / N;

% Plot magnitude spectrum
figure('Position', [100, 100, 1200, 600]);
subplot(1,2,1);
bar(freq_axis, abs(Vleft), 'LineWidth', 0.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Magnitude Spectrum of Musical Note');
grid on;
xlim([0, 5000]);

subplot(1,2,2);
bar(freq_axis(1:2000), abs(Vleft(1:2000)), 'LineWidth', 0.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Zoomed Spectrum (0-2000 Hz)');
grid on;

% Find peaks automatically
[pks, locs] = findpeaks(abs(Vleft), 'MinPeakHeight', max(abs(Vleft))/15, ...
                         'MinPeakDistance', 30);
peak_indices = locs;
fprintf('Found %d peaks\n', length(peak_indices));
fprintf('Peak frequencies (Hz):\n');
for i = 1:min(10, length(peak_indices))
    fprintf('  Peak %d: %.2f Hz (magnitude: %.2f)\n', i, freq_axis(peak_indices(i)), pks(i));
end

K1 = peak_indices(1); % Fundamental frequency index
fundamental_freq = freq_axis(K1);
fprintf('\nFundamental frequency index K1 = %d\n', K1);
fprintf('Fundamental frequency = %.2f Hz\n', fundamental_freq);

% Determine the note
notes = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'};
A4 = 440;
note_number = round(12 * log2(fundamental_freq / A4)) + 69;
octave = floor(note_number / 12) - 1;
note_name = notes{mod(note_number, 12) + 1};
fprintf('This is note: %s%d\n', note_name, octave);

saveas(gcf, 'Figure_i_spectrum.png');

%% Problem (ii) - dB magnitude plot
fprintf('\n=== Problem (ii) ===\n');

% Convert to dB (normalized to 0 dB peak)
Vleft_dB = 20 * log10(abs(Vleft) / max(abs(Vleft)) + eps);

figure('Position', [100, 100, 800, 600]);
plot(freq_axis, Vleft_dB, 'b-', 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Magnitude Spectrum in dB (Normalized to 0 dB peak)');
grid on;
xlim([0, 5000]);
ylim([-80, 5]);

[dBmax, max_idx] = max(Vleft_dB);
fprintf('Maximum dB value dBmax = %.2f dB (at %.2f Hz)\n', dBmax, freq_axis(max_idx));

saveas(gcf, 'Figure_ii_dB_spectrum.png');

%% Problem (iii) - Attenuation filtering
fprintf('\n=== Problem (iii) ===\n');

% Taper function (as provided in assignment)
taper = @(N) (1 - cos(2*pi*(0:N-1)'/(N-1)))/2;

% For att = 40 dB
att = 40;
threshold_dB = dBmax - att;
mask = Vleft_dB >= threshold_dB;

Vedit_40 = Vleft;
Vedit_40(~mask) = 0;

% Reconstruct full spectrum
V_full_40 = [Vedit_40; conj(Vedit_40(end-1:-1:2))];
Vnew_40 = real(ifft(V_full_40));

% Apply taper
Vnew_40_tapered = Vnew_40 .* taper(N);

% For att = 60 dB
att = 60;
threshold_dB = dBmax - att;
mask = Vleft_dB >= threshold_dB;

Vedit_60 = Vleft;
Vedit_60(~mask) = 0;

V_full_60 = [Vedit_60; conj(Vedit_60(end-1:-1:2))];
Vnew_60 = real(ifft(V_full_60));
Vnew_60_tapered = Vnew_60 .* taper(N);

% Plot comparison
figure('Position', [100, 100, 1400, 500]);

subplot(1,3,1);
plot(Vnew_40, 'b-');
xlabel('Sample');
ylabel('Amplitude');
title('Vnew without taper (att=40 dB)');
grid on;
xlim([0, N]);

subplot(1,3,2);
plot(Vnew_40_tapered, 'r-');
xlabel('Sample');
ylabel('Amplitude');
title('Vnew with taper (att=40 dB)');
grid on;
xlim([0, N]);

subplot(1,3,3);
plot(Vnew_60_tapered, 'g-');
xlabel('Sample');
ylabel('Amplitude');
title('Vnew with taper (att=60 dB)');
grid on;
xlim([0, N]);

% Save for att=60 dB
Vsave1 = Vedit_60;
Vee1 = Vnew_60;
save('Vsave1.mat', 'Vsave1');
save('Vee1.mat', 'Vee1');

fprintf('Saved Vsave1 and Vee1 for att=60 dB\n');
fprintf('Number of nonzero entries in Vsave1: %d\n', sum(abs(Vsave1) > 0));

saveas(gcf, 'Figure_iii_tapered_signals.png');

% Optional playback (uncomment for desktop MATLAB)
% soundsc(Vnew_60_tapered, Fs);

%% Problem (iv) - Pure harmonics generation
fprintf('\n=== Problem (iv) ===\n');

% Generate pure harmonic signal
max_harmonic = floor(N2 / K1);
Vedit_pure = zeros(size(Vleft));

% Zeroth harmonic (DC component)
if K1/2 >= 1
    dc_indices = 1:floor(K1/2);
    Vedit_pure(1) = norm(Vleft(dc_indices));
end

% Other harmonics
for h = 1:max_harmonic
    harmonic_idx = h * K1;
    if harmonic_idx <= N2+1
        % Get indices around harmonic
        half_width = floor(K1/2);
        start_idx = max(1, harmonic_idx - half_width);
        end_idx = min(N2+1, harmonic_idx + half_width);
        indices = start_idx:end_idx;
        
        % Set magnitude to norm of surrounding cluster
        if length(indices) > 0
            magnitude = norm(Vleft(indices));
            % Set phase to original phase at peak
            Vedit_pure(harmonic_idx) = magnitude * exp(1j * angle(Vleft(harmonic_idx)));
        end
    end
end

% Reconstruct full signal
V_full_pure = [Vedit_pure; conj(Vedit_pure(end-1:-1:2))];
Vee2 = real(ifft(V_full_pure));

figure('Position', [100, 100, 800, 600]);
plot(Vee2, 'b-', 'LineWidth', 0.5);
xlabel('Sample');
ylabel('Amplitude');
title('Vee2 - Pure Harmonic Signal (Constant Amplitude)');
grid on;

fprintf('Vee2 generated with %d harmonics\n', max_harmonic);
fprintf('Amplitude range: [%.4f, %.4f]\n', min(Vee2), max(Vee2));
save('Vee2.mat', 'Vee2');
saveas(gcf, 'Figure_iv_Vee2.png');

%% Problem (v) - Hamming window analysis
fprintf('\n=== Problem (v) ===\n');

windowed_signal = Vee2 .* hamming(N);

% Plot comparison
figure('Position', [100, 100, 1000, 600]);

subplot(2,1,1);
plot(Vee2(1:min(5000,N)), 'b-');
title('Vee2 (first 5000 samples)');
ylabel('Amplitude');
grid on;

subplot(2,1,2);
plot(windowed_signal(1:min(5000,N)), 'r-');
title('Vee2 with Hamming window (first 5000 samples)');
xlabel('Sample');
ylabel('Amplitude');
grid on;

% Analyze windowing effect
fprintf('Vee2 RMS: %.4f\n', rms(Vee2));
fprintf('Windowed signal RMS: %.4f\n', rms(windowed_signal));
fprintf('Energy reduction due to window: %.2f dB\n', 20*log10(rms(windowed_signal)/rms(Vee2)));

saveas(gcf, 'Figure_v_hamming_comparison.png');

% Optional playback (uncomment for desktop MATLAB)
% soundsc(windowed_signal, Fs);

%% Problem (vi) - Highest harmonic simplification
fprintf('\n=== Problem (vi) ===\n');

% Load Vsave1 from part (iii)
load('Vsave1.mat');

% Count nontrivial harmonics in Vsave1
nonzero_indices = find(abs(Vsave1) > 0);
fprintf('Vsave1 has %d nonzero entries\n', length(nonzero_indices));

% Find highest harmonic index
max_harmonic_idx = max(nonzero_indices);
fprintf('Highest harmonic index: %d (%.2f Hz)\n', max_harmonic_idx, freq_axis(max_harmonic_idx));

% Replace cluster at highest harmonic
half_width = floor(K1/2);
start_idx = max(1, max_harmonic_idx - half_width);
end_idx = min(N2+1, max_harmonic_idx + half_width);
cluster_indices = start_idx:end_idx;

fprintf('Replacing cluster from index %d to %d\n', start_idx, end_idx);

% Replace cluster with single entry
Vedit_modified = Vsave1;
Vedit_modified(cluster_indices) = 0;
if max_harmonic_idx <= length(Vedit_modified)
    Vedit_modified(max_harmonic_idx) = norm(Vsave1(cluster_indices)) * exp(1j * angle(Vsave1(max_harmonic_idx)));
end

% Reconstruct signal
V_full_modified = [Vedit_modified; conj(Vedit_modified(end-1:-1:2))];
Vee3 = real(ifft(V_full_modified));

% Apply taper
Vee3_tapered = Vee3 .* taper(N);

% Plot comparison
figure('Position', [100, 100, 1000, 500]);

subplot(1,2,1);
plot(freq_axis, abs(Vsave1), 'b-', 'LineWidth', 1);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Original Vsave1 Spectrum');
grid on;
xlim([0, 5000]);

subplot(1,2,2);
plot(freq_axis, abs(Vedit_modified), 'r-', 'LineWidth', 1);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Modified Spectrum with Simplified Harmonic');
grid on;
xlim([0, 5000]);

saveas(gcf, 'Figure_vi_spectrum_comparison.png');
save('Vee3.mat', 'Vee3');

% Optional playback (uncomment for desktop MATLAB)
% soundsc(Vee3_tapered, Fs);

%% Problem (vii) - Exponential envelope
fprintf('\n=== Problem (vii) ===\n');

% Load Vee2 from part (iv)
load('Vee2.mat');

% Analyze original vnote envelope using Hilbert transform
envelope_original = abs(hilbert(vnote));
envelope_original = envelope_original / max(envelope_original);

% Find envelope parameters by trial and error
t = (0:N-1)' / N;

% Try different decay rates to match original envelope
% Based on typical musical note decay
c_values = [3, 4, 4.5, 5, 6];
errors = zeros(size(c_values));

figure('Position', [100, 100, 1200, 800]);

for i = 1:length(c_values)
    envelope_candidate = exp(-c_values(i) * t);
    % Calculate error (only on first half where original envelope is reliable)
    error = mean((envelope_candidate(1:floor(N/2)) - envelope_original(1:floor(N/2))).^2);
    errors(i) = error;
end

% Select best c
[~, best_idx] = min(errors);
c_optimal = c_values(best_idx);
fprintf('Optimal decay parameter c = %.1f\n', c_optimal);

% Create final envelope
A = 1;  % Initial amplitude
envelope_final = A * exp(-c_optimal * t);

% Apply envelope to Vee2
Vee4 = Vee2 .* envelope_final;

% Display comparison
subplot(2,2,1);
plot(vnote(1:min(10000,N)), 'b-');
xlabel('Sample');
ylabel('Amplitude');
title('Original vnote (first 10000 samples)');
grid on;

subplot(2,2,2);
plot(Vee4(1:min(10000,N)), 'r-');
xlabel('Sample');
ylabel('Amplitude');
title('Vee4 with Exponential Envelope (first 10000 samples)');
grid on;

subplot(2,2,3);
plot(envelope_final, 'g-', 'LineWidth', 1.5);
hold on;
plot(envelope_original, 'b--', 'LineWidth', 1);
xlabel('Sample');
ylabel('Amplitude');
title('Envelope Comparison');
legend('Exponential (exp(-c*t/N))', 'Original envelope');
grid on;
xlim([0, N]);

% Magnitude spectrum of Vee4
Vee4_fft = fft(Vee4);
Vee4_left = Vee4_fft(1:N2+1);
subplot(2,2,4);
bar(freq_axis, abs(Vee4_left), 'LineWidth', 0.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Magnitude Spectrum of Vee4');
grid on;
xlim([0, 5000]);

saveas(gcf, 'Figure_vii_Vee4_analysis.png');
save('Vee4.mat', 'Vee4');

% Optional playback (uncomment for desktop MATLAB)
% soundsc(Vee4, Fs);

%% Final Summary
fprintf('\n========================================\n');
fprintf('=== PROJECT COMPLETED SUCCESSFULLY ===\n');
fprintf('========================================\n');
fprintf('\nGenerated Files:\n');
fprintf('  Data Files:\n');
fprintf('    - Vsave1.mat (spectrum after 60dB attenuation)\n');
fprintf('    - Vee1.mat (time signal after 60dB attenuation)\n');
fprintf('    - Vee2.mat (pure harmonic signal)\n');
fprintf('    - Vee3.mat (simplified highest harmonic)\n');
fprintf('    - Vee4.mat (final enveloped signal)\n');
fprintf('\n  Figures:\n');
fprintf('    - Figure_i_spectrum.png\n');
fprintf('    - Figure_ii_dB_spectrum.png\n');
fprintf('    - Figure_iii_tapered_signals.png\n');
fprintf('    - Figure_iv_Vee2.png\n');
fprintf('    - Figure_v_hamming_comparison.png\n');
fprintf('    - Figure_vi_spectrum_comparison.png\n');
fprintf('    - Figure_vii_Vee4_analysis.png\n');
fprintf('\nNote: Audio playback is disabled for browser compatibility.\n');
fprintf('To hear the audio, uncomment soundsc() calls and run on desktop MATLAB.\n');