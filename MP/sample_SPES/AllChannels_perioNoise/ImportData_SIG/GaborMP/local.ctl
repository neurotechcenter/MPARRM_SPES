# Template for running Gabor MP Analysis
%INPUT_OUTPUT
Numb_inputs=1
Numb_outputs=1
Mode=parallel
%INPUT
Path=MP/sample_SPES/AllChannels_perioNoise/ImportData_SIG
Header_file=sig.hdr
Calibrate=1
Numb_points=128
Shift_points=128
%OUTPUT
Path=MP/sample_SPES/AllChannels_perioNoise/GaborMP
All_chans=1
Numb_chans=1
Start_chan=1
Start_chan_no=0
Header_file=book.hdr
Type=book
File_format=double
Name_template=mp#.bok
Max_len=600
Chans_per_file=-1
%GABOR_DECOMPOSITION
Max_Iterations=50
