function sg3db=read_sg3_measurements2(filename,fileformat)
%
% This function reads the file <filename> from the ITU-R SG3 databank
% written using the format <fileformat> and returns output variables in the
% cell structure vargout.
% <filename> is a string defining the file in which the data is stored
% <fileformat> is the format with which the data is written in the file:
%               = 'fryderyk_cvs' (implemented)
%               = 'cvs'          (tbi)
%               = 'xml'          (tbi)
%
%  Output variable is a struct sg3db containing the following fields
%  d               - distance between Tx and Rx
%  Ef              - measured field strength at distance d
%  f_GHz           - frequency in GHz
%  Tx_AHaG_m       - Tx antenna height above ground in m
%  RX_AHaG_m       - Rx antenna height above ground in m
%  etc
%
% Author: Ivica Stevanovic, Federal Office of Communications, Switzerland
% Revision History:
% Date            Revision
% 06SEP2013       Introduced corrections in order to read different
%                 versions of .csv file (netherlands data, RCRCU databank and kholod data)
% 22JUL2013       Initial version (IS)

filename1= filename;

sg3db=[];

% read the file

fid=fopen(filename1,'r');
if (fid==-1)
    return;
end

[measurementFolder, measurementFileName, ext] = fileparts(filename1);
[upperPath, deepestFolder, ~] = fileparts(fileparts(filename1));
sg3db.MeasurementFolder = deepestFolder;
sg3db.MeasurementFileName = [measurementFileName, ext];

switch fileformat
    case 'Fryderyk_csv'
        
        sg3db.first_point_transmitter=1;
        sg3db.coveragecode=[];
        sg3db.h_ground_cover=[];
        sg3db.radio_met_code=[];
        
        %% read all the lines of the file
        
        while(1)
            readLine=fgetl(fid);
            if (readLine==-1)
                break
            end
            
            dummy=regexp(readLine,',','split');
            
            
            if strcmp(dummy{1},'First Point Tx or Rx')
                if strcmp(dummy{2},'T')
                    sg3db.first_point_transmitter=1;
                else
                    sg3db.first_point_transmitter=0;
                end
            end
            
            
            if strcmp1(dummy{1},'Tot. Path Length(km):')
                TxRxDistance_km=str2double(dummy{2});
                sg3db.TxRxDistance=TxRxDistance_km;
            end
            
            if strcmp(dummy{1},'Tx site name:')
                TxSiteName=dummy{2};
                sg3db.TxSiteName=TxSiteName;
            end
            
            if strcmp(dummy{1},'Rx site name:')
                RxSiteName=dummy{2};
                sg3db.RxSiteName=RxSiteName;
            end
            
            if strcmp(dummy{1},'Tx Country:')
                TxCountry=dummy{2};
                sg3db.TxCountry=TxCountry;
            end
            
            
            
            
            %% read the height profile
            if strcmp(dummy{1},'Number of Points:')
                %disp('found')
                Npoints=str2num(dummy{2});
                sg3db.coveragecode=[];
                sg3db.h_ground_cover=[];
                sg3db.radio_met_code=[];
                for i=1:Npoints
                    readLine=fgetl(fid);
                    if (readLine==-1)
                        break
                    end
                    dummy=regexp(readLine,',','split');
                    sg3db.x(i)=str2double(dummy{1});
                    sg3db.h_gamsl(i)=str2double(dummy{2});
                    if length(dummy)>2
                        sg3db.coveragecode(i)=str2double(dummy{3});
                        if (length(dummy))>3
                            sg3db.h_ground_cover(i)=str2double(dummy{4});
                            if(length(dummy))>4
                                %Land=4, Coast=3, Sea=1
                                sg3db.radio_met_code(i)=str2double(dummy{5});
                            end
                        end
                        
                    end
                    
                end
            end
            
            %% read the field strength
            if strcmp(dummy{1},'Frequency')
                % read the next line that defines the units
                readLine=fgetl(fid);
                % the next line should be {Begin Measurements} and the one
                % after that the number of measurement records. However, in
                % the Dutch implementation, those two lines are missing.
                % and in the implementations of csv files from RCRU, {Begin
                % Mof Measurements} is there, but the number of
                % measurements (line after) may be missing
                % This is the reason we are checking for these two lines in
                % the following code
                
                dutchflag=true;
                readLine=fgetl(fid);
                if (regexp(readLine,'{Begin of Measurements'))
                    % check if the line after that contains only one number
                    % or the data
                    readLine=fgetl(fid); % the line with the number of records or not
                    dummy=regexp(readLine,',','split');
                    if (length(dummy)>2)
                        if isempty([dummy{2:end}])
                            % this is the number of data - the info we do
                            % not use, read another line
                            readLine=fgetl(fid);
                            dutchflag=false;
                        else
                            %
                            dutchflag=true;
                        end
                    else
                        dutchflag=false;
                        readLine=fgetl(fid);
                    end
                    
                end
                
                % read all the lines until the {End of Measurements} tag
                kindex=1;
                while(1)
                    if(kindex==1)
                        % do not read the new line, but use the one read in
                        % the previous step
                    else
                        readLine=fgetl(fid);
                    end
                    
                    if (readLine==-1)
                        break
                    end
                    if (regexp(readLine,'{End of Measurements}'))
                        break
                    end
                    dummy=regexp(readLine,',','split');
                    
                    f(kindex)=str2double(dummy{1});
                    sg3db.frequency(kindex)=f(kindex);
                    
                    col=2;
                    hTx(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        hTx(kindex)=str2double(dummy{col});
                    end
                    sg3db.hTx(kindex)=hTx(kindex);
                    
                    col=3;
                    hTxeff(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        hTxeff(kindex)=str2double(dummy{col});
                    end
                    sg3db.hTxeff(kindex)=hTxeff(kindex);
                    
                    col=4;
                    hRx(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        hRx(kindex)=str2double(dummy{col});
                    end
                    sg3db.hRx(kindex)=hRx(kindex);
                    
                    col=5;
                    polHVC(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        polHVC(kindex)=str2double(dummy{col});
                    end
                    sg3db.polHVC(kindex)=polHVC(kindex);
                    col=6;
                    
                    TxdBm(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        TxdBm(kindex)=str2double(dummy{col});
                    end
                    sg3db.TxdBm(kindex)=TxdBm(kindex);
                    
                    col=7;
                    MaxLb(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        MaxLb(kindex)=str2double(dummy{col});
                    end
                    sg3db.MaxLb(kindex)=MaxLb(kindex);
                    
                    col=8;
                    Txgn(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        Txgn(kindex)=str2double(dummy{col});
                    end
                    sg3db.Txgn(kindex)=Txgn(kindex);
                    
                    col=9;
                    Rxgn(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        Rxgn(kindex)=str2double(dummy{col});
                    end
                    sg3db.Rxgn(kindex)=Rxgn(kindex);
                    
                    col=10;
                    RxAntDO(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        RxAntDO(kindex)=str2double(dummy{col});
                    end
                    sg3db.RxAntDO(kindex)=RxAntDO(kindex);
                    
                    col=11;
                    ERP_max_horiz(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        ERP_max_horiz(kindex)=str2double(dummy{col});
                    end
                    sg3db.ERPMaxHoriz(kindex)=ERP_max_horiz(kindex);
                    
                    col=12;
                    ERP_max_vertical(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        ERP_max_vertical(kindex)=str2double(dummy{col});
                    end
                    sg3db.ERPMaxVertical(kindex)=ERP_max_vertical(kindex);
                    
                    col=13;
                    ERP_max_total(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        ERP_max_total(kindex)=str2double(dummy{col});
                    end
                    sg3db.ERPMaxTotal(kindex)=ERP_max_total(kindex);
                    
                    col=14;
                    HRP_red(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        HRP_red(kindex)=str2double(dummy{col});
                    end
                    sg3db.HRPred(kindex)=HRP_red(kindex);
                    
                    col=15;
                    Time_percentage(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        Time_percentage(kindex)=str2double(dummy{col});
                    end
                    if(isnan(Time_percentage(kindex)))
                        warning('Time percentage not defined. Default value 50% assumed.');
                        Time_percentage(kindex)=50;
                    end
                    sg3db.TimePercent(kindex)=Time_percentage(kindex);
                    
                    col=16;
                    LwrFS(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        LwrFS(kindex)=str2double(dummy{col});
                    end
                    sg3db.LwrFS(kindex)=LwrFS(kindex);
                    
                    col=17;
                    Field_Strength(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        Field_Strength(kindex)=str2double(dummy{col});
                    end
                    sg3db.MeasuredFieldStrength(kindex)=Field_Strength(kindex);
                    
                    col=18;
                    Basic_Transmission_Loss(kindex)=NaN;
                    if(~isempty(dummy{col}))
                        Basic_Transmission_Loss(kindex)=str2double(dummy{col});
                    end
                    sg3db.BasicTransmissionLoss(kindex)=Basic_Transmission_Loss(kindex);
                    
                    sg3db.RxHeightGainGroup(kindex) = NaN;
                    sg3db.IsTopHeightInGroup(kindex) = NaN;
                    
                    if length(dummy)>18
                        col=19;
                        RX_Height_Gain_Group(kindex)=NaN;
                        if(~isempty(dummy{col}))
                            RX_Height_Gain_Group(kindex)=str2double(dummy{col});
                        end
                        sg3db.RxHeightGainGroup(kindex)=RX_Height_Gain_Group(kindex);
                        
                        col=20;
                        Is_Top_Height_in_Group(kindex)=NaN;
                        if(~isempty(dummy{col}))
                            Is_Top_Height_in_Group(kindex)=str2double(dummy{col});
                        end
                        sg3db.IsTopHeightInGroup(kindex)=Is_Top_Height_in_Group(kindex);
                    end
                    kindex=kindex+1;
                    
                    %Basic transmission loss,RX height gain group,Is top height in group
                end
                
                % Number of different measured data sets
                Ndata=kindex-1;
                sg3db.Ndata=Ndata;
                
                % Update handles structure
                
            end
            
        end
        
    case 'csv'
        warning('Not yet implemented.')
        
    case 'xml'
        warning('Not yet implemented.')
        
end


fclose(fid);

return

