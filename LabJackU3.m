function [x,y] = LabJackU3( op, varargin )
% function [x,y] = LabJackU3( op, varargin )
% 
% this function simplifies talking to a labjack
% 
% Must have MATLAB_LJUD.zip file from 
%	http://labjack.com/support/ud/examples/matlab
% and 'LJUD_Functions' folder must be on path or in the current directory
% 
% inputs:
%	op		operation to perform, options are:
%		temperature	- read internal temp in Kelvin
%		AnalogIn,N	
%			read single-ended analog input from channel N
%		AnalogInDiff,N1,N2	
%			read differential analog input from channels: N1-N2
%		AnalogOut,N1,N2	
%			set analog output channel N1 (0 or 1) to voltage N2
%		DigitalIn,N	- read 0 or 1 on channel N
%		DigitalOut,N1,N2
%			set channel N1 to digital value N2 (0 or 1)
%		StreamAnalogIn,N1,N2,N3
%			stream from channel N1 (can be array of multiple channels)
%			at rate N2 samples/sec for total of N3 seconds
% 
% varargin - currently no options
% 
% 
% examples:
%	T = LabJackU3('temperature')
% %		return internal temperature
%	V2 = LabJackU3('AnalogIn',2) 
% %		return AIN2-GND voltage
%	V6to5 = LabJackU3('AnalogInDiff',6,5) 
% %		return AIN6-AIN5 voltage
%	LabJackU3('AnalogOut',1,3)
% %		set DAC1 to 3 volts
%	D4 = LabJackU3('DigitalIn',4)
% %		read voltage of 0 or 1 on FIO4
%	LabJackU3('DigitalOut',5)
% %		set voltage to 0 or 1 on FIO5
%	[time,V1]=LabJackU3('StreamAnalogIn',1,1000,.3);
% %		stream AIN1 at 1000 Hz for 0.3 seconds
%	[time,Vs]=LabJackU3('StreamAnalogIn',[0,1],5000,1.5);
% %		stream both AIN0 & AIN1 at 5000 Hz for 1.5 seconds
% 
% 
% authors:
% Dan Schmidt wrote the first version
% rewritten by Nathan Tomlin 10/03 b/c labjack commands updated
% nathan.a.tomlin@gmail.com


% default outputs
x=0; y=0;

%check for options
for m = 1:length(varargin),
	if ischar(varargin{m})	% varargin commands are always char
		switch lower(varargin{m})
% 			case 'Address'
% 				if isa(varargin{i+1},'double') %check that next argument is a number
% 					address = varargin{i+1};
% 				else
% 					error(['Address needs to be a number']);
% 				end
		end
	end
end



% check whether device initialized
global OPEN_labjackU3
global DEV_labjackU3
% global ERROR_labjackU3
if isempty(OPEN_labjackU3) || OPEN_labjackU3 ~= 1
    % open device
	ljud_LoadDriver; % Loads LabJack UD Function Library
	ljud_Constants; % Loads LabJack UD constant file
	[Error ljHandle] = ljud_OpenLabJack(LJ_dtU3,LJ_ctUSB,'1',1); % Returns ljHandle for open LabJack
	Error_Message(Error);
	dev = ljHandle;
	DEV_labjackU3 = dev;
	OPEN_labjackU3 = 1;
	
	% reset to factory defaults
	[Error] = ljud_ePut(DEV_labjackU3, LJ_ioPIN_CONFIGURATION_RESET, 0, 0, 0);
	Error_Message(Error)
else
	ljud_Constants; % Loads LabJack UD constant file
end
dev = DEV_labjackU3;




    


switch lower(op)		
	case {'analogin','ain'}	% read single-ended analog input
		% same as diff. measurement where 2nd channel is #31 (grnd)
		% check for valid channel number
		if varargin{1} >= 0 && varargin{1} <= 15
			channel = varargin{1};
		else
			error('AnalogIn - channel out of range');
		end    
		
% 		% reset to factory defaults
% 		[Error] = ljud_ePut(dev, LJ_ioPIN_CONFIGURATION_RESET, 0, 0, 0);
% 		Error_Message(Error)

		% Configure channel to be an analog input
		Error = ljud_AddRequest(dev,LJ_ioPUT_ANALOG_ENABLE_BIT,channel,1,0,0);
		Error_Message(Error)

		% Call eGet function to get AIN single-ended voltage.
		[Error x] = ljud_eGet(dev,LJ_ioGET_AIN,channel,0,0);
		Error_Message(Error)
		
	case {'analogindiff','aindiff'}	% read differential analog inputs
		% check for valid channel numbers
		% ! AIN0-3 aren't meant for diff. meas.
		if varargin{1} >= 4 && varargin{1} <= 15 && varargin{2} >= 4 && varargin{2} <= 15
			channel1 = varargin{1};
			channel2 = varargin{2};
		else
			error('AnalogInDiff - one of the channels is out of range (or support not coded yet, not 4-15)');
		end    
		
% 		% reset to factory defaults
% 		[Error] = ljud_ePut(dev, LJ_ioPIN_CONFIGURATION_RESET, 0, 0, 0);
% 		Error_Message(Error)

		% Configure channel1 to be an analog input
		Error = ljud_AddRequest(dev,LJ_ioPUT_ANALOG_ENABLE_BIT,channel1,1,0,0);
		Error_Message(Error)

		% Configure channel2 to be an analog input
		Error = ljud_AddRequest(dev,LJ_ioPUT_ANALOG_ENABLE_BIT,channel2,1,0,0);
		Error_Message(Error)

		% Call eGet function to get AIN(ch1)-AIN(ch2) differential voltage.
		[Error x] = ljud_eGet(dev,LJ_ioGET_AIN_DIFF,channel1,channel2,30);
		Error_Message(Error)

	case {'temperature','temp'} % read labjack internal temp [K]
		channel = 30;
		% Call eGet function to get AIN single-ended voltage.
		[Error x] = ljud_eGet(dev,LJ_ioGET_AIN,channel,0,0);
		Error_Message(Error)

	case {'analogout','ao'}		% set voltage on analog output
		% check for valid channel number
		if varargin{1} == 0 || varargin{1} == 1
			channel = varargin{1};
		else
			error('AnalogIn - channel out of range');
		end    
		%check for valid voltage number
		if isa(varargin{2},'double') && varargin{2} >= 0 && varargin{2} <= 5
			voltage = varargin{2};
		else
			error('AnalogOut voltage out of range')
		end

% 		% reset to factory defaults
% 		[Error] = ljud_ePut(dev, LJ_ioPIN_CONFIGURATION_RESET, 0, 0, 0);
% 		Error_Message(Error)

		% Call eGet function to get AIN(ch1)-AIN(ch2) differential voltage.
		Error = ljud_ePut(dev,LJ_ioPUT_DAC,channel,voltage,0);
% 		Error = ljud_ePut(dev,LJ_ioPUT_DAC,channel,voltage,0);
		Error_Message(Error)
		
	case {'digitalin','di'}	% read digital input
		% check for valid channel number
		if varargin{1} >= 4 && varargin{1} <= 15
			channel = varargin{1};
		else
			error('DigitalIn - channel out of range');
		end    
		
% 		% reset to factory defaults
% 		[Error] = ljud_ePut(dev, LJ_ioPIN_CONFIGURATION_RESET, 0, 0, 0);
% 		Error_Message(Error)

		% Configure channel to be a digital input
		Error = ljud_AddRequest(dev,LJ_ioPUT_ANALOG_ENABLE_BIT,channel,0,0,0);
		Error_Message(Error)

		% Call eGet function to get AIN single-ended voltage.
		[Error x] = ljud_eGet(dev,LJ_ioGET_DIGITAL_BIT,channel,0,0);
		Error_Message(Error)

	case {'digitalout','do'}	% set digital output
		% check for valid channel number
		if varargin{1} >= 4 && varargin{1} <= 15
			channel = varargin{1};
		else
			error('DigitalOut - channel out of range');
		end    
		%check for 0 or 1
		if varargin{2} == 0 || varargin{2} == 1
			voltage = varargin{2};
		else
			error('DigitalOut must be 0 or 1')
		end
		
% 		% reset to factory defaults
% 		[Error] = ljud_ePut(dev, LJ_ioPIN_CONFIGURATION_RESET, 0, 0, 0);
% 		Error_Message(Error)

		% Configure channel to be a digital output
		Error = ljud_AddRequest(dev,LJ_ioPUT_ANALOG_ENABLE_BIT,channel,0,0,0);
		Error_Message(Error)

		% Call eGet function to get AIN single-ended voltage.
		Error = ljud_ePut(dev,LJ_ioPUT_DIGITAL_BIT,channel,voltage,0);
		Error_Message(Error)

	case {'streamanalogin','streamain'}	% stream single-ended analog input
		% check for valid channel number(s)
		if all(varargin{1} >= 0) && all(varargin{1} <= 15)
			channel = varargin{1};
		else
			error('StreamAnalogIn - channel out of range');
		end    
		num_channels = numel(channel);
		
		% check for valid ScanRate [Hz]
		if varargin{2} >= 0 && varargin{2} <= 50000/num_channels
			ScanRate = varargin{2};
		else
			error('StreamAnalogIn - ScanRate out of range');
		end    
		% check for valid sampling time
		if varargin{3} >= 0
			sampletime = varargin{3};
		else
			error('StreamAnalogIn - sampletime out of range');
		end    
		
		buffertime = 5; % 5 second buffer time
		
		% stream variables
		pausetime = .5;	% time to wait between reads of data from buffer
		global final_array
		final_array = [];
		
% 		% reset to factory defaults
% 		[Error] = ljud_ePut(dev, LJ_ioPIN_CONFIGURATION_RESET, 0, 0, 0);
% 		Error_Message(Error)

		for m = 1:num_channels
			% Configure channel to be an analog input
			Error = ljud_AddRequest(dev,LJ_ioPUT_ANALOG_ENABLE_BIT,channel(m),1,0,0);
			Error_Message(Error)
		end
		
		% Configure Scan Rate
		Error = ljud_AddRequest(dev,LJ_ioPUT_CONFIG,LJ_chSTREAM_SCAN_FREQUENCY,ScanRate,0,0);
		Error_Message(Error)
 
		% Give the driver a buffer (ScanRate * Num_Channels * BufferTime)
		% this is PC RAM buffer, not labjack's internal buffer
		Error = ljud_AddRequest(dev,LJ_ioPUT_CONFIG,LJ_chSTREAM_BUFFER_SIZE,ScanRate*num_channels*buffertime,0,0);
		Error_Message(Error)

		% Configure reads to retrieve whatever data is available without waiting
		Error = ljud_AddRequest(dev,LJ_ioPUT_CONFIG,LJ_chSTREAM_WAIT_MODE,LJ_swNONE,0,0);
		Error_Message(Error)

		% Clear stream channels
		Error = ljud_AddRequest(dev,LJ_ioCLEAR_STREAM_CHANNELS,0,0,0,0);
		Error_Message(Error)

		for m = 1:num_channels
			% Define the scan list AIN#
			Error = ljud_AddRequest(dev,LJ_ioADD_STREAM_CHANNEL,channel(m),0,0,0);
			Error_Message(Error)
		end
		
		% Execute list of above requests
		Error = ljud_GoOne(dev);
		Error_Message(Error)

		%--------------------------------------------------------------------------
		% Get all results just to check for errors
		Error = ljud_GetFirstResult(dev,0,0,0,0,0);
		Error_Message (Error)

		% Run while loop until Error 1006 is returned to ensure that the device has
		% fully configured its channels before continuing.
		while (Error ~= 1006) % 1006 Equates to LJE_NO_MORE_DATA_AVAILABLE
			Error = ljud_GetNextResult(dev,0,0,0,0,0);
			if ((Error ~= 0) && (Error ~= 1006))
				Error_Message(Error)
				break
			end
		end 

		%--------------------------------------------------------------------------
		num_total = ScanRate * sampletime * num_channels;
			
		% Start the Stream
		[Error] = ljud_ePut(dev,LJ_ioSTART_STREAM,0,0,0);
		Error_Message(Error)
		
		k = 0;
		while numel(final_array) < num_total
			k=k+1;

			% Retrieve the current U3 backlog. The UD driver retrieves
			% stream data from the U3 in the background, but if the computer 
			% is too slow for some reason the driver might not be able to read
			% the data as fast as the U3 is acquiring it, and thus there will 
			% be data left over in the U3 buffer. 
			[Error CommBacklog(k)] = ljud_eGet(dev, LJ_ioGET_CONFIG, LJ_chSTREAM_BACKLOG_COMM, 0, 0);
			Error_Message(Error)
			
			% Retrieve the current UD driver backlog. If this is growing, then 
			% the application software is not pulling data from the UD driver 
			% fast enough. 
			[Error UDBacklog(k)] = ljud_eGet(dev, LJ_ioGET_CONFIG, LJ_chSTREAM_BACKLOG_UD, 0, 0);
			Error_Message(Error)
			
			% check whether backlog - adjust pause accordingly
			
			if CommBacklog(k) ~= 0 || UDBacklog(k) ~= 0
				% backlog - decrease wait time
				pausetime = pausetime / 2;
%  				disp(['Comm backlog: ',num2str(CommBacklog),', UD backlog: ',num2str(UDBacklog)])
			else
% 				pausetime = pausetime * 2;
			end
			pausetimelog(k) = pausetime;
 			pause(pausetime)
			
			Scans2Read = ceil(ScanRate * pausetime * 2);
			% Set the number of scans to read. We will request twice the number we
			% expect, to make sure we get everything that is available. 

			% Note the array we pass must be sized to hold enough SAMPLES, 
			% and the Value we pass specifies the number of SCANS to read.		
			% Initialize an array to store data
			array(Scans2Read*num_channels) = double(0);

			% Get the Streamed Data. If you have streamed from more than one
			% channel the data has to be parsed as in this sample.
			[Error Scans2Read return_array] = ljud_eGet_array(dev,LJ_ioGET_STREAM_DATA,LJ_chALL_CHANNELS,Scans2Read,array);
			Error_Message(Error)

			final_array = horzcat(final_array,return_array(1:Scans2Read*num_channels));
			clear return_array
			clear array			
		end
		% Stop the stream
		[Error] = ljud_ePut(dev,LJ_ioSTOP_STREAM,0,0,0);
		Error_Message(Error)
		
% 		if any(CommBacklog ~= 0) || any(UDBacklog ~= 0)
% 			CommBacklog
% 			UDBacklog
% 			pausetimelog
% 		end
		
		% See how big the final array is
		num_pts = numel(final_array);
		num_samples = num_pts / num_channels;
		
		% Reshape the long final array
		y_large = [reshape(final_array,num_channels,num_samples)];
		
		% want to make returned data of predictable length, so throw away
		% extra points
		y = y_large(:,1:ScanRate*sampletime);
		
		% timing array
% 		x = [1:num_samples]/ScanRate;
		x = [1:ScanRate*sampletime]/ScanRate;
		
	case {'streamanalogin_old','streamain_old'}	% stream single-ended analog input
		% check for valid channel number(s)
		if all(varargin{1} >= 0) && all(varargin{1} <= 15)
			channel = varargin{1};
		else
			error('StreamAnalogIn - channel out of range');
		end    
		num_channels = numel(channel);
		
		% check for valid ScanRate [Hz]
		if varargin{2} >= 0 && varargin{2} <= 50000/num_channels
			ScanRate = varargin{2};
		else
			error('StreamAnalogIn - ScanRate out of range');
		end    
		% check for valid sampling time
		if varargin{3} >= 0
			sampletime = varargin{3};
		else
			error('StreamAnalogIn - sampletime out of range');
		end    
		
		buffertime = 5; % 5 second buffer time
		
		% stream variables
		pausetime = .5;	% time to wait between reads of data from buffer
		Loops = round(sampletime/pausetime); % Number of times to read data from the buffer
		global final_array
		final_array = [];
		
% 		% reset to factory defaults
% 		[Error] = ljud_ePut(dev, LJ_ioPIN_CONFIGURATION_RESET, 0, 0, 0);
% 		Error_Message(Error)

		for m = 1:num_channels
			% Configure channel to be an analog input
			Error = ljud_AddRequest(dev,LJ_ioPUT_ANALOG_ENABLE_BIT,channel(m),1,0,0);
			Error_Message(Error)
		end
		
		% Configure Scan Rate
		Error = ljud_AddRequest(dev,LJ_ioPUT_CONFIG,LJ_chSTREAM_SCAN_FREQUENCY,ScanRate,0,0);
		Error_Message(Error)
 
		% Give the driver a buffer (ScanRate * Num_Channels * BufferTime)
		% this is PC RAM buffer, not labjack's internal buffer
		Error = ljud_AddRequest(dev,LJ_ioPUT_CONFIG,LJ_chSTREAM_BUFFER_SIZE,ScanRate*num_channels*buffertime,0,0);
		Error_Message(Error)

		% Configure reads to retrieve whatever data is available without waiting
		Error = ljud_AddRequest(dev,LJ_ioPUT_CONFIG,LJ_chSTREAM_WAIT_MODE,LJ_swNONE,0,0);
		Error_Message(Error)

		% Clear stream channels
		Error = ljud_AddRequest(dev,LJ_ioCLEAR_STREAM_CHANNELS,0,0,0,0);
		Error_Message(Error)

		for m = 1:num_channels
			% Define the scan list AIN#
			Error = ljud_AddRequest(dev,LJ_ioADD_STREAM_CHANNEL,channel(m),0,0,0);
			Error_Message(Error)
		end
		
		% Execute list of above requests
		Error = ljud_GoOne(dev);
		Error_Message(Error)

		%--------------------------------------------------------------------------
		% Get all results just to check for errors
		Error = ljud_GetFirstResult(dev,0,0,0,0,0);
		Error_Message (Error)

		% Run while loop until Error 1006 is returned to ensure that the device has
		% fully configured its channels before continuing.
		while (Error ~= 1006) % 1006 Equates to LJE_NO_MORE_DATA_AVAILABLE
			Error = ljud_GetNextResult(dev,0,0,0,0,0);
			if ((Error ~= 0) && (Error ~= 1006))
				Error_Message(Error)
				break
			end
		end 

		%--------------------------------------------------------------------------
		Scans2Read = round(ScanRate * pausetime * 2);
			% Set the number of scans to read. We will request twice the number we
			% expect, to make sure we get everything that is available. 

		% Start the Stream
		[Error] = ljud_ePut(dev,LJ_ioSTART_STREAM,0,0,0);
		Error_Message(Error)
		
		for n = 0:Loops
			% Retrieve the current U3 backlog. The UD driver retrieves
			% stream data from the U3 in the background, but if the computer 
			% is too slow for some reason the driver might not be able to read
			% the data as fast as the U3 is acquiring it, and thus there will 
			% be data left over in the U3 buffer. 
			[Error CommBacklog(n+1)] = ljud_eGet(dev, LJ_ioGET_CONFIG, LJ_chSTREAM_BACKLOG_COMM, double(0), 0);
			Error_Message(Error)
			
			% Retrieve the current UD driver backlog. If this is growing, then 
			% the application software is not pulling data from the UD driver 
			% fast enough. 
			[Error UDBacklog(n+1)] = ljud_eGet(dev, LJ_ioGET_CONFIG, LJ_chSTREAM_BACKLOG_UD, double(0), 0);
			Error_Message(Error)
			
			pause(pausetime)
			
			% Note the array we pass must be sized to hold enough SAMPLES, 
			% and the Value we pass specifies the number of SCANS to read.		
			% Initialize an array to store data
			array(Scans2Read*num_channels) = double(0);

			% Get the Streamed Data. If you have streamed from more than one
			% channel the data has to be parsed as in this sample.
			[Error Scans2Read return_array] = ljud_eGet_array(dev,LJ_ioGET_STREAM_DATA,LJ_chALL_CHANNELS,Scans2Read,array);
			Error_Message(Error)

			final_array = horzcat(final_array,return_array(1:Scans2Read*num_channels));
			clear return_array
			clear array
			
		end
		% Stop the stream
		[Error] = ljud_ePut(dev,LJ_ioSTOP_STREAM,0,0,0);
		Error_Message(Error)
		
		if any(CommBacklog ~= 0) || any(UDBacklog ~= 0)
			CommBacklog
			UDBacklog
		end
		%--------------------------------------------------------------------------

		% See how big the final array is
		num_pts = numel(final_array);
		num_samples = num_pts / num_channels;
		
		% Reshape the long final array
		y = [reshape(final_array,num_channels,num_samples)];

		% timing array
		x = [1:num_samples]/ScanRate;
		
	case {'test'} 

end    
