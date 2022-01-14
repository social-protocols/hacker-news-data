.headers off
select "Analyze & optimize...";
analyze;
PRAGMA optimize;
select "Vacuum...";
VACUUM;
