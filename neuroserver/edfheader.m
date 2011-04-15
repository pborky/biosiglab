function [ server, HDR ] = edfheader( server, equip )
%EDFHEADER Deals with header data in edf format.
%
%   Usage
%       [ server, HDR ] = edfheader( server, equip )
%       inputs
%           server  - structure holding the server control variables
%           equip   - vector of equip ids if empty all EEG is used.
%       output
%           server  - structure holding the server control variables
%           HDR     - output data structure

    %% Get data from server
    if nargin == 1,
        equip = server.eeg(1);
    end
    [ server, data ] = neuroclientwrapper( server, ['getheader ', int2str(equip)] );
    
    % Folowing code is cut from eeglab toolbox...

    %% Initialization
    HDR = struct();
    HDR.FILE.stdout = 1;
    HDR.FILE.stderr = 2;
    LABELS = {}; 
    ReRefMx = [];
    HDR.NS = NaN; 
    HDR.SampleRate = NaN;
    HDR.T0 = repmat(nan,1,6);    
    HDR.Filter.Notch    = NaN; 
    HDR.Filter.LowPass  = NaN; 
    HDR.Filter.HighPass = NaN; 
    HDR.FLAG = [];
    HDR.FLAG.FILT = 0; 	% FLAG if any filter is applied; 
    HDR.FLAG.TRIGGERED = 0; % the data is untriggered by default
    HDR.FLAG.UCAL = 0;   % FLAG for UN-CALIBRATING
    HDR.FLAG.OVERFLOWDETECTION = 0;
    HDR.FLAG.FORCEALLCHANNEL = 0;
    HDR.FLAG.OUTPUT = 'double';
    HDR.EVENT.TYP = []; 
    HDR.EVENT.POS = [];
    GDFTYPES=[0 1 2 3 4 5 6 7 16 17 18 255+[1 12 22 24] 511+[1 12 22 24]];
    GDFTYP_BYTE=zeros(1,512+64);
    GDFTYP_BYTE(256+(1:64))=(1:64)/8;
    GDFTYP_BYTE(512+(1:64))=(1:64)/8;
    GDFTYP_BYTE(1:19)=[1 1 1 2 2 4 4 8 8 4 8 0 0 0 0 0 4 8 16]';
    H2idx = [16 80 8 8 8 8 8 80 8 32];
    HDR.ErrNo = 0; 
    HANDEDNESS = {'unknown','right','left','equal'}; 
    GENDER  = {'X','Male','Female'};
    SCALE13 = {'unknown','no','yes'};
    SCALE14 = {'unknown','no','yes','corrected'};
    
    if (length(data) >=6) && strcmp('200 OK',char(data(1,1:6))),
        data = data(2,:);
    else 
        if (length(data) >=6) && strcmp('400 BAD REQUEST',char(data(1,1:15))),
            fprintf(2,'Wrong data: 400 BAD REQUEST\n');
            return;
        else
            fprintf(2,'Wrong data: Unknown\n');
            return;            
        end
    end
    if length(data)<192,
            HDR.ErrNo = [64,HDR.ErrNo];
            return;
    end;
    H1 = char(data(1:192));
    HDR.VERSION=char(H1(1:8));                     % 8 Byte  Versionsnummer 
    if ~(strcmp(HDR.VERSION,'0       ') || all(abs(HDR.VERSION)==[255,abs('BIOSEMI')]) || strcmp(HDR.VERSION(1:3),'GDF'))
        HDR.ErrNo = [1,HDR.ErrNo];
        if ~strcmp(HDR.VERSION(1:3),'   '); % if not a scoring file, 
            %return; 
        end;
    end;
    if strcmp(char(H1(1:8)),'0       '),
        HDR.VERSION = 0; 
    elseif all(abs(H1(1:8))==[255,abs('BIOSEMI')]), 
        HDR.VERSION = -1; 
    elseif all(H1(1:3)==abs('GDF')),
        HDR.VERSION = str2double(char(H1(4:8))); 
    else
        HDR.ErrNo = [1,HDR.ErrNo];
        if ~strcmp(HDR.VERSION(1:3),'   '); % if not a scoring file, 
            %return; 
        end;
    end;		
    HDR.Patient.Sex = 0;
    HDR.Patient.Handedness = 0;
    if 0,
        HDR.Patient.Weight = NaN;
        HDR.Patient.Height = NaN;
        HDR.Patient.Impairment.Visual = NaN;
        HDR.Patient.Smoking = NaN;
        HDR.Patient.AlcoholAbuse = NaN;
        HDR.Patient.DrugAbuse = NaN;
        HDR.Patient.Medication = NaN;
    end;
    
    if HDR.VERSION > 0,  %strcmp(HDR.TYPE,'GDF'),
        disp ('Error: GDF is not implemented.');
        return; % todo fix following
        if (HDR.VERSION >= 1.90)
            HDR.PID = deblank(char(H1(9:84)));                  % 80 Byte local patient identification
            HDR.RID = deblank(char(H1(89:156)));                % 80 Byte local recording identification
            [HDR.Patient.Id,tmp] = strtok(HDR.PID,' ');
            HDR.Patient.Name = tmp(2:end); 

            HDR.Patient.Medication   = SCALE13{bitand(floor(H1(85)/64),3)+1};
            HDR.Patient.DrugAbuse    = SCALE13{bitand(floor(H1(85)/16),3)+1};
            HDR.Patient.AlcoholAbuse = SCALE13{bitand(floor(H1(85)/4),3)+1};
            HDR.Patient.Smoking      = SCALE13{bitand(H1(85),3)+1};
            tmp = abs(H1(86:87)); tmp(tmp==0) = NaN; tmp(tmp==255) = inf;
            HDR.Patient.Weight = tmp(1);
            HDR.Patient.Height = tmp(2);
            HDR.Patient.Sex = bitand(H1(88),3); %GENDER{bitand(H1(88),3)+1};
            HDR.Patient.Handedness = HANDEDNESS{bitand(floor(H1(88)/4),3)+1};
            HDR.Patient.Impairment.Visual = SCALE14{bitand(floor(H1(88)/16),3)+1};
            if H1(156)>0, 
                    HDR.RID = deblank(char(H1(89:156)));
            else
                    HDR.RID = deblank(char(H1(89:152)));
                    %HDR.REC.LOC.RFC1876  = 256.^[0:3]*reshape(H1(153:168),4,4);
                    HDR.REC.LOC.Version   = abs(H1(156));
                    HDR.REC.LOC.Size      = dec2hex(H1(155));
                    HDR.REC.LOC.HorizPre  = dec2hex(H1(154));
                    HDR.REC.LOC.VertPre   = dec2hex(H1(153));
            end;
            HDR.REC.LOC.Latitude  = H1(157:160)*256.^[0:3]'/3600000;
            HDR.REC.LOC.Longitude = H1(161:164)*256.^[0:3]'/3600000;
            HDR.REC.LOC.Altitude  = H1(165:168)*256.^[0:3]'/100;

            tmp = H1(168+[1:16]);
            % little endian fixed point number with 32 bits pre and post comma 
            t1 = tmp(1:8 )*256.^[-4:3]';
            HDR.T0 = datevec(t1);
            t2 = tmp(9:16)*256.^[-4:3]';
            HDR.Patient.Birthday = datevec(t2);
            if (t2 > 1) && (t2 < t1),
                HDR.Patient.Age = floor((t1-t2)/365.25);
            end;
            HDR.REC.Equipment = fread(HDR.FILE.FID,[1,8],'uint8');   
            tmp = fread(HDR.FILE.FID,[1,6],'uint8');
            if (HDR.VERSION < 2.1)	
                HDR.REC.IPaddr = tmp(6:-1:1); 
            end;
            tmp = fread(HDR.FILE.FID,[1,3],'uint16'); 
            tmp(tmp==0)=NaN;
            HDR.Patient.Headsize = tmp;
            tmp = fread(HDR.FILE.FID,[3,2],'float32');
            HDR.ELEC.REF = tmp(:,1)';
            HDR.ELEC.GND = tmp(:,2)';
        else
            HDR.PID = deblank(char(H1(9:88)));                  % 80 Byte local patient identification
            HDR.RID = deblank(char(H1(89:168)));                % 80 Byte local recording identification
            [HDR.Patient.Id,tmp] = strtok(HDR.PID,' ');
            HDR.Patient.Name = tmp(2:end); 

            tmp = repmat(' ',1,22);
            tmp([1:4,6:7,9:10,12:13,15:16,18:21]) = char(H1(168+[1:16]));
            HDR.T0(1:6)   = str2double(tmp);
            HDR.T0(6)     = HDR.T0(6)/100;
            HDR.reserved1 = fread(HDR.FILE.FID,[1,8*3+20],'uint8');   % 44 Byte reserved
            HDR.REC.Equipment  = HDR.reserved1(1:8);
            HDR.REC.Hospital   = HDR.reserved1(9:16);
            HDR.REC.Technician = HDR.reserved1(17:24);
        end;

        %if str2double(HDR.VERSION(4:8))<0.12,
        if (HDR.VERSION < 0.12),
            HDR.HeadLen  = str2double(H1(185:192));    % 8 Byte  Length of Header
        elseif (HDR.VERSION < 1.92)
            HDR.HeadLen  = H1(185:188)*256.^[0:3]';    % 8 Byte  Length of Header
            HDR.reserved = H1(189:192);
        else 
            HDR.HeadLen  = H1(185:186)*256.^[1:2]';    % 8 Byte  Length of Header
        end;
        HDR.H1 = H1; 

        %HDR.NRec = fread(HDR.FILE.FID,1,'int64');     % 8 Byte # of data records
        HDR.NRec = fread(HDR.FILE.FID,1,'int32');      % 8 Byte # of data records
        fread(HDR.FILE.FID,1,'int32');      % 8 Byte # of data records
        %if strcmp(HDR.VERSION(4:8),' 0.10')
        if ((abs(HDR.VERSION - 0.10) < 2*eps) || (HDR.VERSION > 2.20)),
            HDR.Dur = fread(HDR.FILE.FID,1,'float64');	% 8 Byte # duration of data record in sec
        else
            tmp  = fread(HDR.FILE.FID,2,'uint32');  % 8 Byte # duration of data record in sec
            %tmp1 = warning('off');
            HDR.Dur = tmp(1)./tmp(2);
            %warning(tmp1);
        end;
        tmp = fread(HDR.FILE.FID,2,'uint16');     % 4 Byte # of signals
        HDR.NS = tmp(1);
    else
        H1(193:256) = data(193:256);
        H1 = char(H1);
        HDR.PID = deblank(char(H1(9:88)));                  % 80 Byte local patient identification
        HDR.RID = deblank(char(H1(89:168)));                % 80 Byte local recording identification
        [HDR.Patient.Id,tmp] = strtok(HDR.PID,' ');
        [tmp1,tmp] = strtok(tmp,' ');
        [tmp1,tmp] = strtok(tmp,' ');
        HDR.Patient.Name = tmp(2:end); 

        tmp = find((H1<32) | (H1>126)); 		%%% syntax for Matlab
        if ~isempty(tmp) %%%%% not EDF because filled out with ASCII(0) - should be spaces
            %H1(tmp)=32; 
            HDR.ErrNo=[1025,HDR.ErrNo];
        end;

        tmp = repmat(' ',1,22);
        tmp([3:4,6:7,9:10,12:13,15:16,18:19]) = H1(168+[7:8,4:5,1:2,9:10,12:13,15:16]);
        tmp1 = str2double(tmp);
        if length(tmp1)==6,
            HDR.T0(1:6) = tmp1;
        end;

        if any(isnan(HDR.T0)),
            HDR.ErrNo = [1032,HDR.ErrNo];
            tmp = H1(168 + [1:16]);
            tmp(tmp=='.' | tmp==':' | tmp=='/' | tmp=='-') = ' ';
            tmp1 = str2double(tmp(1:8));
            if length(tmp1)==3,
                HDR.T0 = tmp1([3,2,1]);
            end;	
            tmp1 = str2double(tmp(9:16));
            if length(tmp1)==3,
                HDR.T0(4:6) = tmp1; 
            end;
            if any(isnan(HDR.T0)),
                HDR.ErrNo = [2,HDR.ErrNo];
            end;
        end;

        % Y2K compatibility until year 2084
        if HDR.T0(1) < 85    % for biomedical data recorded in the 1950's and converted to EDF
            HDR.T0(1) = 2000+HDR.T0(1);
        elseif HDR.T0(1) < 100
            HDR.T0(1) = 1900+HDR.T0(1);
        %else % already corrected, do not change
        end;

        HDR.HeadLen = str2double(H1(185:192));           % 8 Bytes  Length of Header
        HDR.reserved1=H1(193:236);              % 44 Bytes reserved   
        HDR.NRec    = str2double(H1(237:244));     % 8 Bytes  # of data records
        HDR.Dur     = str2double(H1(245:252));     % 8 Bytes  # duration of data record in sec
        HDR.NS      = str2double(H1(253:256));     % 4 Bytes  # of signals
        HDR.AS.H1 = H1;	                     % for debugging the EDF Header

        if strcmp(HDR.reserved1(1:4),'EDF+'),	% EDF+ specific header information 
            [HDR.Patient.Id,   tmp] = strtok(HDR.PID,' ');
            [sex, tmp] = strtok(tmp,' ');
            [bd, tmp] = strtok(tmp,' ');
            [HDR.Patient.Name, tmp] = strtok(tmp,' ');
            if length(sex)>0,
                HDR.Patient.Sex = any(sex(1)=='mM') + any(sex(1)=='Ff')*2;
            else
                HDR.Patient.Sex = 0; % unknown 
            end; 
            if (length(bd)==11),
                HDR.Patient.Birthday = zeros(1,6); 
                bd(bd=='-') = ' '; 
                [n,v,s] = str2double(bd,' ');
                month_of_birth = strmatch(lower(s{2}),{'jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'},'exact');
                if ~isempty(month_of_birth)
                        v(2) = 0;
                end
                if any(v)
                    HDR.Patient.Birthday(:) = NaN;
                else
                    HDR.Patient.Birthday(1) = n(3);
                    HDR.Patient.Birthday(2) = month_of_birth;
                    HDR.Patient.Birthday(3) = n(1);
                    HDR.Patient.Birthday(4) = 12;
                end;
            end; 

            [chk, tmp] = strtok(HDR.RID,' ');
            if ~strcmp(chk,'Startdate')
                fprintf(2,'Warning SOPEN: EDF+ header is corrupted.\n');
            end;
            [HDR.Date2, tmp] = strtok(tmp,' ');
            [HDR.RID, tmp] = strtok(tmp,' ');
            [HDR.REC.Technician, tmp] = strtok(tmp,' ');
            [HDR.REC.Equipment, tmp] = strtok(tmp,' ');
        end; 
    
                
        if any(size(HDR.NS)~=1) %%%%% not EDF because filled out with ASCII(0) - should be spaces
            fprintf(2, 'Warning SOPEN (GDF/EDF/BDF): invalid NS-value in header of %s\n',HDR.FileName);
            HDR.ErrNo=[1040,HDR.ErrNo];
            HDR.NS=1;
        end;
        % Octave assumes HDR.NS is a matrix instead of a scalare. Therefore, we need
        % Otherwise, eye(HDR.NS) will be executed as eye(size(HDR.NS)).
        HDR.NS = HDR.NS(1);  
                
        if isempty(HDR.HeadLen) %%%%% not EDF because filled out with ASCII(0) - should be spaces
            HDR.ErrNo=[1056,HDR.ErrNo];
            HDR.HeadLen=256*(1+HDR.NS);
        end;

        if isempty(HDR.NRec) %%%%% not EDF because filled out with ASCII(0) - should be spaces
            HDR.ErrNo=[1027,HDR.ErrNo];
            HDR.NRec = -1;
        end;

        if isempty(HDR.Dur) %%%%% not EDF because filled out with ASCII(0) - should be spaces
            HDR.ErrNo=[1088,HDR.ErrNo];
            HDR.Dur=30;
        end;

        if  any(HDR.T0>[2084 12 31 24 59 59]) || any(HDR.T0<[1985 1 1 0 0 0])
            HDR.ErrNo = [4, HDR.ErrNo];
        end;
        
        if HDR.VERSION <= 0,
            idx1=cumsum([0 H2idx]);
            idx2=HDR.NS*idx1;

            h2=zeros(HDR.NS,256);
            if length(data)<256+HDR.NS*256,
                HDR.ErrNo=[8,HDR.ErrNo];
                return; 
                
            end;
            H2 = data(257:(256+HDR.NS*256));

            %tmp=find((H2<32) | (H2>126)); % would confirm 
            tmp = find((H2<32) | ((H2>126) & (H2~=255) & (H2~=181)& (H2~=230)));
            if ~isempty(tmp) %%%%% not EDF because filled out with ASCII(0) - should be spaces
                H2(tmp) = 32; 
                HDR.ErrNo = [1026,HDR.ErrNo];
            end;

            for k=1:length(H2idx);
                %disp([k size(H2) idx2(k) idx2(k+1) H2idx(k)]);
                h2(:,idx1(k)+1:idx1(k+1))=reshape(H2(idx2(k)+1:idx2(k+1)),H2idx(k),HDR.NS)';
            end;
            h2=char(h2);

            HDR.Label      =    cellstr(h2(:,idx1(1)+1:idx1(2)));
            HDR.Transducer =    cellstr(h2(:,idx1(2)+1:idx1(3)));
            HDR.PhysDim    =    cellstr(h2(:,idx1(3)+1:idx1(4)));
            HDR.PhysMin    = str2double(cellstr(h2(:,idx1(4)+1:idx1(5))))';
            HDR.PhysMax    = str2double(cellstr(h2(:,idx1(5)+1:idx1(6))))';
            HDR.DigMin     = str2double(cellstr(h2(:,idx1(6)+1:idx1(7))))';
            HDR.DigMax     = str2double(cellstr(h2(:,idx1(7)+1:idx1(8))))';
            HDR.PreFilt    =            h2(:,idx1(8)+1:idx1(9));
            HDR.AS.SPR     = str2double(cellstr(h2(:,idx1(9)+1:idx1(10))));
            %if ~all(abs(HDR.VERSION)==[255,abs('BIOSEMI')]),
            if (HDR.VERSION ~= -1),
                HDR.GDFTYP     = 3*ones(1,HDR.NS);	%	datatype
            else
                HDR.GDFTYP     = (255+24)*ones(1,HDR.NS);	%	datatype
            end;

            if isempty(HDR.AS.SPR), 
                fprintf(2, 'Warning SOPEN (GDF/EDF/BDF): invalid SPR-value in header of %s\n',HDR.FileName);
                HDR.AS.SPR=ones(HDR.NS,1);
                HDR.ErrNo=[1028,HDR.ErrNo];
            end;
        elseif (HDR.NS>0)
            if (ftell(HDR.FILE.FID)~=256),
                error('position error');
            end;	 
            HDR.Label      =  char(fread(HDR.FILE.FID,[16,HDR.NS],'uint8')');		
            HDR.Transducer =  cellstr(char(fread(HDR.FILE.FID,[80,HDR.NS],'uint8')'));	

            if (HDR.NS<1),	% hack for a problem with Matlab 7.1.0.183 (R14) Service Pack 3

            elseif (HDR.VERSION < 1.9),
                HDR.PhysDim    =  char(fread(HDR.FILE.FID,[ 8,HDR.NS],'uint8')');
                HDR.PhysMin    =       fread(HDR.FILE.FID,[1,HDR.NS],'float64');	
                HDR.PhysMax    =       fread(HDR.FILE.FID,[1,HDR.NS],'float64');	
                tmp            =       fread(HDR.FILE.FID,[1,2*HDR.NS],'int32');
                HDR.DigMin     =  tmp((1:HDR.NS)*2-1);
                tmp            =       fread(HDR.FILE.FID,[1,2*HDR.NS],'int32');
                HDR.DigMax     =  tmp((1:HDR.NS)*2-1);
                HDR.PreFilt    =  char(fread(HDR.FILE.FID,[80,HDR.NS],'uint8')');	%	
                HDR.AS.SPR     =       fread(HDR.FILE.FID,[ 1,HDR.NS],'uint32')';	%	samples per data record
                HDR.GDFTYP     =       fread(HDR.FILE.FID,[ 1,HDR.NS],'uint32');	%	datatype

            else
                tmp	       =  char(fread(HDR.FILE.FID,[6,HDR.NS],'uint8')');
                % HDR.PhysDim    =  char(fread(HDR.FILE.FID,[6,HDR.NS],'uint8')');
                HDR.PhysDimCode =      fread(HDR.FILE.FID,[1,HDR.NS],'uint16');
                HDR.PhysMin    =       fread(HDR.FILE.FID,[1,HDR.NS],'float64');	
                HDR.PhysMax    =       fread(HDR.FILE.FID,[1,HDR.NS],'float64');	
                HDR.DigMin     =       fread(HDR.FILE.FID,[1,HDR.NS],'float64');
                HDR.DigMax     =       fread(HDR.FILE.FID,[1,HDR.NS],'float64');
                HDR.PreFilt    =  char(fread(HDR.FILE.FID,[80-12,HDR.NS],'uint8')');	%	
                HDR.Filter.LowPass  =  fread(HDR.FILE.FID,[1,HDR.NS],'float32');	% 
                HDR.Filter.HighPass =  fread(HDR.FILE.FID,[1,HDR.NS],'float32');	%
                HDR.Filter.Notch    =  fread(HDR.FILE.FID,[1,HDR.NS],'float32');	%
                HDR.AS.SPR     =       fread(HDR.FILE.FID,[1,HDR.NS],'uint32')';	% samples per data record
                HDR.GDFTYP     =       fread(HDR.FILE.FID,[1,HDR.NS],'uint32');	        % datatype
                HDR.ELEC.XYZ   =       fread(HDR.FILE.FID,[3,HDR.NS],'float32')';	% datatype
                if (HDR.VERSION < 2.19)
                    tmp    =       fread(HDR.FILE.FID,[HDR.NS, 1],'uint8');	        % datatype
                    tmp(tmp==255) = NaN; 
                    HDR.Impedance = 2.^(tmp/8);
                    fseek(HDR.FILE.FID, HDR.NS*19, 'cof');	                        % datatype
                else 
                    tmp    =       fread(HDR.FILE.FID,[5,HDR.NS],'float32');	% datatype
                    ch     =       bitand(HDR.PhysDimCode, hex2dec('ffe0'))==4256;       % channel with voltage data  
                    HDR.Impedance(ch) = tmp(1,ch);
                    HDR.Impedance(~ch)= NaN;
                    ch     =       bitand(HDR.PhysDimCode, hex2dec('ffe0'))==4288;       % channel with impedance data  
                    HDR.fZ(ch) = tmp(1,ch);                                         % probe frequency
                    HDR.fZ(~ch)= NaN;
                end;
            end;
        end;
        
        HDR.SPR=1;
        

        if (HDR.NS>0),
			if ~isfield(HDR,'THRESHOLD')
                HDR.THRESHOLD  = [HDR.DigMin',HDR.DigMax'];       % automated overflow detection 
                if (HDR.VERSION == 0) && HDR.FLAG.OVERFLOWDETECTION,   % in case of EDF and OVERFLOWDETECTION
                    fprintf(2,'WARNING SOPEN(EDF): Physical Max/Min values of EDF data are not necessarily defining the dynamic range.\n'); 
                    fprintf(2,'   Hence, OVERFLOWDETECTION might not work correctly. See also EEG2HIST and read \n'); 
                    fprintf(2,'   http://dx.doi.org/10.1016/S1388-2457(99)00172-8 (A. Schl�gl et al. Quality Control ... Clin. Neurophysiol. 1999, Dec; 110(12): 2165 - 2170).\n'); 
                    fprintf(2,'   A copy is available here, too: http://www.dpmi.tugraz.at/schloegl/publications/neurophys1999_2165.pdf \n'); 
				end;
			end; 
            if any(HDR.PhysMax==HDR.PhysMin), HDR.ErrNo=[1029,HDR.ErrNo]; end;	
            if any(HDR.DigMax ==HDR.DigMin ), HDR.ErrNo=[1030,HDR.ErrNo]; end;	
            HDR.Cal = (HDR.PhysMax-HDR.PhysMin)./(HDR.DigMax-HDR.DigMin);
            HDR.Off = HDR.PhysMin - HDR.Cal .* HDR.DigMin;
			if any(~isfinite(HDR.Cal)),
                fprintf(2,'WARNING SOPEN(GDF/BDF/EDF): Scaling factor is not defined in following channels:\n');
                find(~isfinite(HDR.Cal))',
                HDR.Cal(~isfinite(HDR.Cal))=1; 
                HDR.FLAG.UCAL = 1;  
			end;
			
            HDR.AS.SampleRate = HDR.AS.SPR / HDR.Dur;

            chan = 1:HDR.NS;
            if HDR.VERSION == 0,
                if strcmp(HDR.reserved1(1:4),'EDF+')
                    tmp = strmatch('EDF Annotations',HDR.Label);
                    chan(tmp)=[];
                end; 
            end;
            
            for k=chan,
                if (HDR.AS.SPR(k)>0)
                    HDR.SPR = lcm(HDR.SPR,HDR.AS.SPR(k));
                end;
            end;
            HDR.SampleRate = HDR.SPR/HDR.Dur;

            HDR.AS.spb = sum(HDR.AS.SPR);	% Samples per Block
            HDR.AS.bi  = [0;cumsum(HDR.AS.SPR(:))]; 
            HDR.AS.BPR = ceil(HDR.AS.SPR.*GDFTYP_BYTE(HDR.GDFTYP+1)'); 
            if any(HDR.AS.BPR ~= HDR.AS.SPR.*GDFTYP_BYTE(HDR.GDFTYP+1)');
                fprintf(2,'\nError SOPEN (GDF/EDF/BDF): block configuration in file %s not supported.\n',HDR.FileName);
            end;
            HDR.AS.SAMECHANTYP = all(HDR.AS.BPR == (HDR.AS.SPR.*GDFTYP_BYTE(HDR.GDFTYP+1)')) && ~any(diff(HDR.GDFTYP)); 
            HDR.AS.bpb = sum(ceil(HDR.AS.SPR.*GDFTYP_BYTE(HDR.GDFTYP+1)'));	% Bytes per Block
            HDR.Calib  = [HDR.Off; diag(HDR.Cal)];

		else  % (if HDR.NS==0)
			HDR.THRESHOLD = [];
			HDR.AS.SPR = [];
			HDR.Calib  = zeros(1,0); 
			HDR.AS.bpb = 0; 
			HDR.GDFTYP = [];
			HDR.Label  = {};
        end;        
        
        if HDR.VERSION<1.9,
            HDR.Filter.LowPass = repmat(nan,1,HDR.NS);
            HDR.Filter.HighPass = repmat(nan,1,HDR.NS);
            HDR.Filter.Notch = repmat(nan,1,HDR.NS);
            for k=1:HDR.NS,
                tmp = HDR.PreFilt(k,:);

                ixh=strfind(tmp,'HP');
                ixl=strfind(tmp,'LP');
                ixn=strfind(tmp,'Notch');
                ix =strfind(lower(tmp),'hz');

                [v,c,errmsg]=sscanf(tmp,'%f - %f Hz');
                if (isempty(errmsg) && (c==2)),
                    HDR.Filter.LowPass(k) = max(v);
                    HDR.Filter.HighPass(k) = min(v);
                else 
                    if any(tmp==';')
                        [tok1,tmp] = strtok(tmp,';');
                        [tok2,tmp] = strtok(tmp,';');
                        [tok3,tmp] = strtok(tmp,';');
                    else
                        [tok1,tmp] = strtok(tmp,' ');
                        [tok2,tmp] = strtok(tmp,' ');
                        [tok3,tmp] = strtok(tmp,' ');
                    end;
                    [T1, F1 ] = strtok(tok1,': ');
                    [T2, F2 ] = strtok(tok2,': ');
                    [T3, F3 ] = strtok(tok3,': ');

                    [F1 ] = strtok(F1,': ');
                    [F2 ] = strtok(F2,': ');
                    [F3 ] = strtok(F3,': ');

                    F1(find(F1==','))='.';
                    F2(find(F2==','))='.';
                    F3(find(F3==','))='.';

                    if strcmp(F1,'DC'), F1='0'; end;
                    if strcmp(F2,'DC'), F2='0'; end;
                    if strcmp(F3,'DC'), F3='0'; end;

                    tmp = strfind(lower(F1),'hz');
                    if ~isempty(tmp), F1=F1(1:tmp-1); end;
                    tmp = strfind(lower(F2),'hz');
                    if ~isempty(tmp), F2=F2(1:tmp-1); end;
                    tmp = strfind(lower(F3),'hz');
                    if ~isempty(tmp), F3=F3(1:tmp-1); end;

                    tmp = str2double(F1); 
                    if isempty(tmp),tmp=NaN; end; 
                    if strcmp(T1,'LP'), 
                        HDR.Filter.LowPass(k) = tmp;
                    elseif strcmp(T1,'HP'), 
                        HDR.Filter.HighPass(k)= tmp;
                    elseif strcmp(T1,'Notch'), 
                        HDR.Filter.Notch(k)   = tmp;
                    end;
                    tmp = str2double(F2); 
                    if isempty(tmp),tmp=NaN; end; 
                    if strcmp(T2,'LP'), 
                        HDR.Filter.LowPass(k) = tmp;
                    elseif strcmp(T2,'HP'), 
                        HDR.Filter.HighPass(k)= tmp;
                    elseif strcmp(T2,'Notch'), 
                        HDR.Filter.Notch(k)   = tmp;
                    end;
                    tmp = str2double(F3); 
                    if isempty(tmp),tmp=NaN; end; 
                    if strcmp(T3,'LP'), 
                        HDR.Filter.LowPass(k) = tmp;
                    elseif strcmp(T3,'HP'), 
                        HDR.Filter.HighPass(k)= tmp;
                    elseif strcmp(T3,'Notch'), 
                        HDR.Filter.Notch(k)   = tmp;
                    end;
                    %catch
                    %        fprintf(2,'Cannot interpret: %s\n',HDR.PreFilt(k,:));
                end;
            end;
        end
        HDR.AS.EVENTTABLEPOS = -1;
        
    end 
end