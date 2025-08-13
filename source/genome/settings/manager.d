module genome.settings.manager;

import genome.settings.config;
import genome.settings.attributes;
import std.stdio : readln;
import std.file : exists, isDir, write, mkdir;
import std.path : dirName;
import std.conv : to;
import std.traits : Fields, FieldNameTuple;
import jsonizer : readJSON, toJSONString, writeJSON;
import colorize : fg, color, cwriteln;

ConfigManager configManager;

/// Read data from stdin with prompt
/// Params:
///   prompt = text prompt
/// Returns: read data
private T ReadWithPrompt(T)(dstring prompt)
{
	import std.string;
	import std.array;

	cwriteln!dstring(prompt);
	return to!T(lineSplitter(readln()).array[0]);
}
/// Ask user about config editing (edit config if user answer == yesAnswer)
/// Params:
///   prompt = text prompt
///   yesAnswer = user "yes" answer
/// Returns: true if user answered yesAnswer, false in other case
private bool AskAboutEditConfig(TConfig, alias configInstance)(dstring prompt, dstring yesAnswer = "y"d)
{
    bool wantRedactConfig = ReadWithPrompt!dstring(prompt) == yesAnswer;
    if(!wantRedactConfig) return false;
    
    import std.traits : hasUDA, getUDAs;
    static foreach (i, name; FieldNameTuple!TConfig)
    {
        // Only process fields with the AskUser attribute
        static if (hasUDA!(__traits(getMember, TConfig, name), AskUser))
        {
            //for avoid symbols overlapping
            {
                alias member = __traits(getMember, configInstance, name);

                // Get the AskUser attribute instance
                enum attrs = getUDAs!(member, AskUser);
                    
                // There should be only one AskUser attribute per field
                enum description = attrs[0].Description;

                alias FieldType = Fields!TConfig[i];
                auto promptMsg = "Enter value for "~name~" ("~description~"):";
                auto value = ReadWithPrompt!FieldType(promptMsg);
                __traits(getMember, configInstance, name) = value;
            }
        }
    }    

    return true;
}

/// Ask user about config saving (save config if user answer == yesAnswer)
/// Params:
///   filePath = save file path
///   prompt = text prompt
///   yesAnswer = user "yes" answer
private static void AskAboutSaveConfig(TConfig, alias configInstance)
(string filePath, dstring prompt, dstring yesAnswer = "y"d)
{
    bool wantSaveConfig = ReadWithPrompt!dstring(prompt) == yesAnswer;
    if(!wantSaveConfig) return;
    writeJSON!TConfig(filePath, configInstance);
}


/// Manages all settings and configurations for Atom
public struct ConfigManager
{
    private enum configsPath = "configs/";
    private enum spawnConfigPath = configsPath ~ "spawn.json";
    private enum agentConfigPath = configsPath ~ "agent.json";
    private enum simulationConfigPath = configsPath ~ "simulation.json";

    /// Run Config Manager
    public void run()
    {
        cwriteln("Genome config manager".color(fg.yellow));

        LoadConfigWithFeedback!(SpawnConfig, gsc)(spawnConfigPath);
        LoadConfigWithFeedback!(AgentConfig, gat)(agentConfigPath);
        LoadConfigWithFeedback!(SimulationConfig, gsic)(simulationConfigPath);

        if(AskAboutEditConfig!(SpawnConfig, gsc)("Do you want to edit spawn config? (y/n)"))
            AskAboutSaveConfig!(SpawnConfig, gsc)(spawnConfigPath, "Do you want to save config? (y/n)");

        if(AskAboutEditConfig!(AgentConfig, gat)("Do you want to edit agent config? (y/n)"))
            AskAboutSaveConfig!(AgentConfig, gat)(agentConfigPath, "Do you want to save config? (y/n)");

        if(AskAboutEditConfig!(SimulationConfig, gsic)("Do you want to edit simulation config? (y/n)"))
            AskAboutSaveConfig!(SimulationConfig, gsic)(simulationConfigPath, "Do you want to save config? (y/n)");
    }

    public void updateConfigs()
    {
        TryLoadConfig!(SpawnConfig, gsc)(spawnConfigPath);
        TryLoadConfig!(AgentConfig, gat)(agentConfigPath);
        TryLoadConfig!(SimulationConfig, gsic)(simulationConfigPath);
    }

    private bool TryLoadConfig(TConfig, alias configInstance)(string filePath)
    {
        if (exists(configsPath) && isDir(configsPath))
        {
            if(exists(filePath))
                configInstance = readJSON!TConfig(filePath);
            else 
            {
                write(filePath, toJSONString!TConfig(configInstance));
                return false;
            }
        } 
        else
        {
            mkdir(configsPath);
            write(filePath, toJSONString!TConfig(configInstance));
            return false;
        } 

        return true;
    }

    private void LoadConfigWithFeedback(TConfig, alias configInstance)(string filePath)
    {
        enum successLoadMessage = "Config loaded successfully.";
        enum loadErrorMessage = "Could not load config. Using default settings.";

        bool couldLoadConfig = TryLoadConfig!(TConfig, configInstance)(filePath);

        if(!couldLoadConfig) cwriteln((loadErrorMessage ~ " " ~ filePath).color(fg.red));        
        else cwriteln(successLoadMessage.color(fg.green));
    }
}