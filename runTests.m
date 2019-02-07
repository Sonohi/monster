import matlab.unittest.TestSuite;
% Test Channel
monsterLog('Testing Channel functions...','NFO')
suite = TestSuite.fromFolder('channel', 'IncludingSubfolders', true);
result = run(suite);

% Test eNB
monsterLog('Testing eNB functions...','NFO')
suite = TestSuite.fromFolder('enb', 'IncludingSubfolders', true);
result = run(suite);