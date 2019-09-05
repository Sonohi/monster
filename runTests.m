import matlab.unittest.TestSuite;
% Test Channel
disp('Testing Channel functions...');
suite = TestSuite.fromFolder('channel', 'IncludingSubfolders', true);
result = run(suite);

% Test Backhaul
%disp();
%suite = TestSuite.fromFolder('backhaul','IncludingSubfolders', true);
%result = run(suite);

% Test eNB
disp('Testing eNB functions...');
suite = TestSuite.fromFolder('enb', 'IncludingSubfolders', true);
result = run(suite);

% Test UE
disp('Testing UE functions...');
suite = TestSuite.fromFolder('ue', 'IncludingSubfolders', true);
result = run(suite);

% Test MetricRecorder
disp('Testing MetricRecorder functions...');
suite = TestSuite.fromFolder('results', 'IncludingSubfolders', true);
result = run(suite);

% Test Monster (simulation)
disp('Testing Monster functions...');
suite = TestSuite.fromFolder('tests', 'IncludingSubfolders', true);
result = run(suite);