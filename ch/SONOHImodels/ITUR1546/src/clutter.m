function [RxClutterCode RxP1546Clutter R2external] = clutter(i, ClutterCodeType)
% [ClutterClass P1546ClutterClass R] = clutter(i, ClutterCode)
% This function maps the value i of a given clutter code type into
% the corresponding clutter class description, P1546 clutter class description
% and clutter height R.
% The implemented ClutterCodeTypes are:
% 'OFCOM' (as defined in the SG3DB database on SUI data from 2012
% 'TDB'   (as defined in the RCRU database and UK data) http://www.rcru.rl.ac.uk/njt/linkdatabase/linkdatabase.php
% 'NLCD'  (as defined in the National Land Cover Dataset) http://www.mrlc.gov/nlcd06_leg.php
% 'LULC'  (as defined in Land Use and Land Clutter database) http://transition.fcc.gov/Bureaus/Engineering_Technology/Documents/bulletins/oet72/oet72.pdf
% 'GlobCover' (as defined in ESA's GlobCover land cover maps) http://due.esrin.esa.int/globcover/
% 'DNR1812' (as defined in the implementation tests for DNR P.1812)
% 'default' (land paths, rural area, R = 10 m)
%
%
% Rev   Date        Author                          Description
%-------------------------------------------------------------------------------
% v2    29Apr15     Ivica Stevanovic, OFCOM         Introduced 'default' option for ClutterCodeTypes
% v1    26SEP13     Ivica Stevanovic, OFCOM         Introduced it as a function

if strcmp(ClutterCodeType,'OFCOM')
    
    if i==0	RxClutterCode='Unknown';
    elseif i==1	RxClutterCode='Water (salt)';
    elseif i==2	RxClutterCode='Water (fresh)';
    elseif i==3	RxClutterCode='Road/Freeway';
    elseif i==4	RxClutterCode='Bare land';
    elseif i==5	RxClutterCode='Bare land/rock';
    elseif i==6	RxClutterCode='Cultivated land';
    elseif i==7	RxClutterCode='Scrub';
    elseif i==8	RxClutterCode='Forest';
    elseif i==9	RxClutterCode='Low dens. suburban';
    elseif i==10 RxClutterCode='Suburban';
    elseif i==11 RxClutterCode='Low dens. urban';
    elseif i==12 RxClutterCode='Urban';
    elseif i==13 RxClutterCode='Dens. urban';
    elseif i==14 RxClutterCode='High dens. urban';
    elseif i==15 RxClutterCode='High rise industry';
    elseif i==16 RxClutterCode='Skyscraper';
    else RxClutterCode='Unknown data';
    end
    
    
    
    if (i==8 || i==12)
        RxP1546Clutter='Urban';
        R2external=15;
    elseif (i==1 || i==2)
        RxP1546Clutter='Sea';
        R2external=10;
    elseif (i<8 && i>2)
        RxP1546Clutter='Rural';
        R2external=10;
    elseif (i<=11 && i>8)
        RxP1546Clutter='Suburban';
        R2external=10;
    elseif (i<=16 && i>11)
        RxP1546Clutter='Dense Urban';
        R2external=20;
    else
        RxP1546Clutter='';
        R2external=[];
    end
    
elseif strcmp(ClutterCodeType,'TDB')
    
    if i==0	RxClutterCode='No data'; RxP1546Clutter=''; R2external=[];
    elseif i==1	RxClutterCode='Fields';     RxP1546Clutter='Rural'; R2external=10;
    elseif i==2	RxClutterCode='Road';       RxP1546Clutter='Rural'; R2external=10;
    elseif i==3	RxClutterCode='BUILDINGS';	RxP1546Clutter='Urban'; R2external=20;
    elseif i==4	RxClutterCode='URBAN';      RxP1546Clutter='Urban'; R2external=20;
    elseif i==5	RxClutterCode='SUBURBAN';	RxP1546Clutter='Suburban'; R2external=10;
    elseif i==6	RxClutterCode='VILLAGE';	RxP1546Clutter='Suburban'; R2external=10;
    elseif i==7	RxClutterCode='SEA';		RxP1546Clutter='Adjacent to Sea'; R2external=10;
    elseif i==8	RxClutterCode='LAKE';		RxP1546Clutter='Adjacent to Sea'; R2external=10;
    elseif i==9	RxClutterCode='RIVER';		RxP1546Clutter='Rural'; R2external=10;
    elseif i==10	RxClutterCode='CONIFER';RxP1546Clutter='Rural'; R2external=10;
    elseif i==11	RxClutterCode='NON_CONIFER'; RxP1546Clutter='Rural'; R2external=10;
    elseif i==12	RxClutterCode='MUD';		 RxP1546Clutter='Rural'; R2external=10;
    elseif i==13   	RxClutterCode='ORCHARD';	 RxP1546Clutter='Rural'; R2external=10;
    elseif i==14	RxClutterCode='MIXED_TREES'; RxP1546Clutter='Urban'; R2external=20;
    elseif i==15	RxClutterCode='DENSE_URBAN'; RxP1546Clutter='Dense Urban'; R2external=30;
    else     RxClutterCode='Unknown data'; RxP1546Clutter=''; R2external=[];
    end
elseif strcmp(ClutterCodeType,'NLCD')
    if i==11	RxClutterCode='Open Water';                         RxP1546Clutter='Adjacent to Sea'; R2external=10;
    elseif i==12	RxClutterCode='Perennial Ice/Snow';             RxP1546Clutter='Rural'; R2external=10;
        
    elseif i==21	RxClutterCode='Developed, Open Space';          RxP1546Clutter='Suburban'; R2external=10;
    elseif i==22	RxClutterCode='Developed, Low Intensity';       RxP1546Clutter='Suburban'; R2external=10;
    elseif i==23	RxClutterCode='Developed, Medium Intensity';    RxP1546Clutter='Suburban'; R2external=10;
    elseif i==24	RxClutterCode='Developed High Intensity';       RxP1546Clutter='Urban'; R2external=20;
        
    elseif i==31	RxClutterCode='Barren Land (Rock/Sand/Clay)';   RxP1546Clutter='Rural'; R2external=10;
        
    elseif i==41	RxClutterCode='Deciduous Forest';               RxP1546Clutter='Urban'; R2external=20;
    elseif i==42	RxClutterCode='Evergreen Forest';               RxP1546Clutter='Urban'; R2external=20;
    elseif i==43	RxClutterCode='Mixed Forest';                   RxP1546Clutter='Urban'; R2external=20;
        
    elseif i==51	RxClutterCode='Dwarf Scrub';                    RxP1546Clutter='Rural'; R2external=10;
    elseif i==52	RxClutterCode='Shrub/Scrub';                    RxP1546Clutter='Rural'; R2external=10;
        
    elseif i==71	RxClutterCode='Grassland/Herbaceous';           RxP1546Clutter='Rural'; R2external=10;
    elseif i==72	RxClutterCode='Sedge/Herbaceous';               RxP1546Clutter='Rural'; R2external=10;
    elseif i==73	RxClutterCode='Lichens - Alaska only';          RxP1546Clutter='Rural'; R2external=10;
    elseif i==74	RxClutterCode='Moss - Alaska only';             RxP1546Clutter='Rural'; R2external=10;
        
    elseif i==81	RxClutterCode='Pasture/Hay';                    RxP1546Clutter='Rural'; R2external=10;
    elseif i==82	RxClutterCode='Cultivated Crops';               RxP1546Clutter='Rural'; R2external=10;
        
    elseif i==90	RxClutterCode='Woody Wetlands';                 RxP1546Clutter='Adjacent to Sea'; R2external=10;
    elseif i==95	RxClutterCode='Emergent Herbaceous Wetlands';   RxP1546Clutter='Adjacent to Sea'; R2external=10;
    else RxClutterCode='Unknown data'; RxP1546Clutter=''; R2external=[];
    end
elseif strcmp(ClutterCodeType,'LULC')
    
    if i==11	RxClutterCode='Residential';                                RxP1546Clutter='Urban'; R2external=20;
    elseif i==12	RxClutterCode='Commercial services';                        RxP1546Clutter='Urban'; R2external=20;
    elseif i==13	RxClutterCode='Industrial';                                 RxP1546Clutter='Urban'; R2external=20;
    elseif i==14	RxClutterCode='Transportation, communications, utilities';	RxP1546Clutter='Rural'; R2external=10;
    elseif i==15	RxClutterCode='Industrial and commercial complexes';        RxP1546Clutter='Urban'; R2external=20;
    elseif i==16	RxClutterCode='Mixed urban and built-up lands';	            RxP1546Clutter='Suburban'; R2external=10;
    elseif i==17	RxClutterCode='Other urban and built-up land';	            RxP1546Clutter='Suburban'; R2external=10;
        
    elseif i==21	RxClutterCode='Cropland and pasture';                       RxP1546Clutter='Rural'; R2external=10;
    elseif i==22	RxClutterCode='Orchards, groves, vineyards, nurseries, and horticultural';	RxP1546Clutter='Rural'; R2external=10;
    elseif i==23	RxClutterCode='Confined feeding operations';                RxP1546Clutter='Rural'; R2external=10;
    elseif i==24	RxClutterCode='Other agricultural land';                    RxP1546Clutter='Rural'; R2external=10;
    elseif i==31	RxClutterCode='Herbaceous rangeland';                       RxP1546Clutter='Rural'; R2external=10;
    elseif i==32	RxClutterCode='Shrub and brush rangeland';                  RxP1546Clutter='Rural'; R2external=10;
    elseif i==33	RxClutterCode='Mixed rangeland';                            RxP1546Clutter='Rural'; R2external=10;
        
    elseif i==41	RxClutterCode='Deciduous forest land';                      RxP1546Clutter='Urban'; R2external=20;
    elseif i==42	RxClutterCode='Evergreen forest land';                      RxP1546Clutter='Urban'; R2external=20;
    elseif i==43	RxClutterCode='Mixed forest land';                          RxP1546Clutter='Urban'; R2external=20;
        
    elseif i==51	RxClutterCode='Streams and canals';                         RxP1546Clutter='Adjacent to Sea'; R2external=10;
    elseif i==52	RxClutterCode='Lakes';                                      RxP1546Clutter='Adjacent to Sea'; R2external=10;
    elseif i==53	RxClutterCode='Reservoirs';                                 RxP1546Clutter='Adjacent to Sea'; R2external=10;
    elseif i==54	RxClutterCode='Bays and estuaries';                         RxP1546Clutter='Adjacent to Sea'; R2external=10;
        
    elseif i==61	RxClutterCode='Forested wetland';                           RxP1546Clutter='Urban'; R2external=20;
    elseif i==62	RxClutterCode='Non-forest wetland';                         RxP1546Clutter='Adjacent to Sea'; R2external=10;
        
    elseif i==71	RxClutterCode='Dry salt flats';                             RxP1546Clutter='Rural'; R2external=10;
    elseif i==72	RxClutterCode='Beaches';                                    RxP1546Clutter='Adjacent to Sea'; R2external=10;
    elseif i==73	RxClutterCode='Sandy areas other than beaches';             RxP1546Clutter='Rural'; R2external=10;
    elseif i==74	RxClutterCode='Bare exposed rock';                          RxP1546Clutter='Rural'; R2external=10;
    elseif i==75	RxClutterCode='Strip mines, quarries, and gravel pits';     RxP1546Clutter='Rural'; R2external=10;
    elseif i==76	RxClutterCode='Transitional areas';                         RxP1546Clutter='Rural'; R2external=10;
    elseif i==77	RxClutterCode='Mixed barren land';                          RxP1546Clutter='Rural'; R2external=10;
        
    elseif i==81	RxClutterCode='Shrub and brush tundra';                     RxP1546Clutter='Rural'; R2external=10;
    elseif i==82	RxClutterCode='Herbaceous tundra';                          RxP1546Clutter='Rural'; R2external=10;
    elseif i==83	RxClutterCode='Bare ground';                                RxP1546Clutter='Rural'; R2external=10;
    elseif i==84	RxClutterCode='Wet tundra';                                 RxP1546Clutter='Rural'; R2external=10;
    elseif i==85	RxClutterCode='Mixed tundra';                               RxP1546Clutter='Rural'; R2external=10;
        
    elseif i==91	RxClutterCode='Perennial snowfields';                       RxP1546Clutter='Rural'; R2external=10;
    elseif i==92	RxClutterCode='Glaciers';                                   RxP1546Clutter='Rural'; R2external=10;
    else RxClutterCode='Unknown data'; RxP1546Clutter=''; R2external=[];
    end
    
elseif strcmp(ClutterCodeType,'GlobCover')
    if i==1     	RxClutterCode='Water/Sea';                                  RxP1546Clutter='Sea';   R2external=10;
    elseif i==2 	RxClutterCode='Open/Rural';                                 RxP1546Clutter='Rural'; R2external=10;
    elseif i==3     RxClutterCode='Suburban';                                   RxP1546Clutter='Suburban'; R2external=10;
    elseif i==4     RxClutterCode='Urban/trees/forest';                         RxP1546Clutter='Urban'; R2external=15;
    elseif i==5     RxClutterCode='Dense Urban';                                RxP1546Clutter='Dense Urban'; R2external=20;
    else RxClutterCode='Unknown data'; RxP1546Clutter=''; R2external=[];
    end
    
elseif strcmp(ClutterCodeType,'DNR1812')
    if i==0     	RxClutterCode='Inland';                                  RxP1546Clutter='Rural';  R2external=10;
    elseif i==1 	RxClutterCode='Coastal';                                 RxP1546Clutter='Sea'; R2external=10;
    elseif i==2     RxClutterCode='Sea';                                     RxP1546Clutter='Sea'; R2external=10;
    else RxClutterCode='Unknown data'; RxP1546Clutter=''; R2external=[];
    end
    
elseif strcmpi(ClutterCodeType,'default')
    warning('Clutter code type set to default:')
    warning('Rural, R = 10 m');
    RxClutterCode='default';
    RxP1546Clutter='Rural';
    R2external=10;

else
    RxClutterCode='';
    RxP1546Clutter='';
    R2external=[];
    
end

return
