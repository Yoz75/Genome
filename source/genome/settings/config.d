module genome.settings.config;
import genome.settings.attributes;
import jsonizer;

/// Global spawn config
SpawnConfig globalSpawnConfig;
/// Global agent config
AgentConfig globalAgentConfig;
/// Global simulation config
SimulationConfig globalSimulationConfig;

/// Alias for GlobalSpawnConfig to avoid long names in code.
alias gsc = globalSpawnConfig;
alias gat = globalAgentConfig;
alias gsic = globalSimulationConfig;

/// Related to spawning settings
struct SpawnConfig
{
    mixin JsonizeMe;
@jsonize:
public:
    @AskUser("frequency of food spawning"d) float foodSpawnFrequency = 1;
    @AskUser("frequency of spikes spawning"d) float spikeSpawnFrequency = 1;
    @AskUser("frequency of agents spawning at start of the simulation"d) float agentSpawnFrequency = 1;

    @AskUser("how much frames food exists?") int maxFoodAliveFrames = 50;    
    @AskUser("how much frames spikes exists?") int maxSpikeAliveFrames = 50;    
}

/// Related to agents settings
struct AgentConfig
{
    mixin JsonizeMe;
@jsonize:
public:
    @AskUser("energy of agents at start of simulation"d) float baseEnergy = 100;

    @AskUser("cost of walking"d) float walkEnergyCost = 1;

    @AskUser("energy damage of starving (every tick)"d) float starveEnergy = .1;
    @AskUser("energy gain from eating other agents"d) float cannibalismEnergy = 2.5;
    @AskUser("energy gain from eating food"d) float foodEnergy = 10;
    @AskUser("damage gain from eating a spike"d) float spikeEnergyDamage = 999;

    @AskUser("how many instructions in agent's genome?"d) int genomeSize = 64;
    @AskUser("maximal instruction's value. Use -1 to use only instructions"d) int maxInstructionValue = 64;
    @AskUser("maximal executed commands per frame"d) int maxExecutedCommands = 2;
    @AskUser("minimal count of genome mutations"d) int minMutationsCount = 0;
    @AskUser("maximal count of genome mutations"d) int maxMutationsCount = 5;
}

/// Other settings
struct SimulationConfig
{
    mixin JsonizeMe;
@jsonize:
    @AskUser("x map size"d) int xMapSize = 512;
    @AskUser("y map size"d) int yMapSize = 512;
    @AskUser("zoom sensetivity"d) float zoomSensetivity = 1.5;
}

enum RenderMode
{
    fullscreen,
    borderless
}