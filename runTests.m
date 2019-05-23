import matlab.unittest.TestSuite;
% Test Channel
disp('Testing Channel functions...');
suite = TestSuite.fromFolder('channel', 'IncludingSubfolders', true);
result = run(suite);

% Test eNB
disp('Testing eNB functions...');
suite = TestSuite.fromFolder('enb', 'IncludingSubfolders', true);
result = run(suite);

% Test UE
disp('Testing UE functions...');
suite = TestSuite.fromFolder('ue', 'IncludingSubfolders', true);
result = run(suite);