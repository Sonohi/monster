function alldefined=checkInput(data)

alldefined=true;

in=data.PTx;
if (~isnan(in))
    if(in<=0)
    warning( 'Transmission power P must be defined and positive' );
    alldefined=false;
    return
    end
else
    warning( 'Transmission power P must be defined and positive' );
    alldefined=false;
    return
end

in=data.f;
if (~isnan(in))
    if(in<30 || in> 3000)
    warning( 'Frequency f must be defined within 30 MHz - 3000 MHz' );
    alldefined=false;
    return
    end
else
    warning( 'Frequency f must be defined within 30 MHz - 3000 MHz' );
    alldefined=false;
    return
end

in=data.t;
errormsg='Time percentage must be defined within 1% - 50%';
if (~isnan(in))
    if(in<1 || in> 50)
    warning(errormsg);
    alldefined=false;
    return
    end
else
    warning(errormsg);
    alldefined=false;
    return
end
    
in=data.q;
errormsg='Location variability must be defined within 1% - 99%';
if (~isnan(in))
    if(in<1 || in> 99)
    warning(errormsg);
    alldefined=false;
    return
    end
else
    warning(errormsg);
    alldefined=false;
    return
end

in=data.heff;
errormsg='Effective height of the transmitter antenna not defined';
if (isnan(in))
    warning(errormsg);
    alldefined=false;
    return
else
%     if (in<=0)
%         warning('Effective height must be a positive number');
%         alldefined=false;
%         return
%     end
    if(isempty(in))
        warning('Effective height of the transmitter antenna not defined');
        alldefined=false;
        return
    end
end

in=data.area;
errormsg='Receiver area type must be defined';
if (isempty(in))
    warning(errormsg);
    alldefined=false;
    return
end


if (data.NN == 0)
        warning( 'There must be at least one path type defined.' );
        alldefined=false;
        return
end

if isempty(data.d_v)
        warning( 'There must be at least one path length defined.' );
        alldefined=false;
        return
end

if isempty(data.path_c)
        warning( 'There must be at least one path type defined.' );
        alldefined=false;
        return
end 


for ii=1: length(data.path_c) 
    if(isnan(data.d_v(ii)))
        warning( 'Path type and path distances are not properly defined.' );
        alldefined=false;
        return
    end
    if(data.d_v(ii)<=0)
       warning( 'Path distance must be a positive number.' );
        alldefined=false;
        return
    end   
end
