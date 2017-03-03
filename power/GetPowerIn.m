function [ Pin ] = GetPowerIn( rbUsed, rbMax,  bsType)
%Compute P_in as in [1], according to the load and of the type of BS. The
%type of BS specifies also P_max, the number of transceiver elements.
%[1] Auer, G., Giannini, V., Desset, C., Godor, I., Skillermark, P., Olsson, 
%M., Imran, M.A., Sabella, D., Gonzalez, M.J., Blume, O. and Fehske, A., 2011. 
%How much energy is needed to run a wireless network?. IEEE Wireless Communications, 18(5).

switch bsType
    case 'macro'
        ntrx = 6;
        Pmax = 20; % W
        P0 = 130; % W
        deltaP = 4.7;
        Psleep = 75; % W
    case 'rrh'
        ntrx = 6;
        Pmax = 20; % W
        P0 = 84; % W, due to reduced feeder losses
        deltaP = 2.8;
        Psleep = 56; % W
    case 'micro'
        ntrx = 2;
        Pmax = 6.3; % W
        P0 = 56; % W
        deltaP = 2.6;
        Psleep = 39.0; % W
    case 'pico'
        ntrx = 2;
        Pmax = 0.13; % W
        P0 = 6.8; % W
        deltaP = 4.0;
        Psleep = 4.3; % W
    case 'femto'
        ntrx = 2;
        Pmax = 0.05; % W
        P0 = 4.8; % W
        deltaP = 8.0;
        Psleep = 2.9; % W
    otherwise
        error('Unknown BS type');
end

Pout = Pmax * rbUsed/rbMax; % check this assumption

if(Pout == 0)
    Pin = Psleep;
else
    Pin = ntrx*P0 + deltaP*Pout;
end
end

