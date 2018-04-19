function isequal = strcmp1(str1, str2)
% This function compares two strings (by previously removing any white
% spaces and open/close brackets from the strings, and changing them to
% lower case).
% Author: Ivica Stevanovic, Federal Office of Communications, Switzerland
% Revision History:
% Date            Revision
% 22JUL2013       Initial version (IS)

    isequal = false;
    str1 = regexprep(str1,'\s', '');
    str2 = regexprep(str2,'\s', '');
    str1 = regexprep(str1,'\(','');
    str2 = regexprep(str2,'\(','');
    str1 = regexprep(str1,'\)','');
    str2 = regexprep(str2,'\)','');
    str1 = lower(str1);
    str2 = lower(str2);
    isequal = strcmp(str1, str2);
return


