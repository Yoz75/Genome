import genome.simulation;
import genome.settings.manager;
import colorize;
import std.stdio : readln;

void main()
{
	configManager.run();

	try
	{
		Simulation simulation;
		simulation.run();
	}	
	//NO, DSCANNER, THAT'S A GOOD IDEA. USER WILL SEE ERROR MESSAGE ANYWAY. BUT BEAUTIFUL OR WITH STACK TRACE - WE DECIDE.
	catch(Exception ex)
	{
		string errorMessage = "Ooops! Simulation exited with an error:\n" ~ ex.msg;
		cwriteln(errorMessage.color(fg.red));
		readln();
	}
}