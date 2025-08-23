module genome.agent;

import genome.simobject;
import genome.map;
import genome.rendering;
import genome.food;
import genome.spike;
import genome.settings.config;
import std.random;
import std.range;
import dlib.container.array;

alias NumericInstruction = ubyte;

/// Genome instructions for agents.
public enum Instruction : NumericInstruction
{
    /// Stop executing this genome
    ret = 0,
    /// Move at to the specified direction. Next byte = x direction, 
    /// Second next byte = y direction.
    /// Zero means no movement
    /// Don't move if something is forward.
    walk,
    /// Unconditionally jump to adress at the next instruction
    jump,
    /// Divide agent and stop executing genome. Set child's PC to next instruction
    divide,
    /// Kill self
    apoptose,
    /// Set genome's instruction at next instruction to value at second next instruction
    set,
    /// Eat thing at relative position (x = next, y = secondnext)
    eat,
    /// Save current energy to agent's register
    saveEnergy,
    /// Compare register and next instruction, set flags. If register is less than value, set carry flag
    compare,
    /// Jump to address at next instruction if corresponding flag is true
    jumpCarry,
    /// ditto
    jumpGreater,
    /// ditto
    jumpEquals,
    /// ditto
    jumpLess,
    /// Look at an object at relative position (same as walk and eat) and to the register it's type 
    /// (based on LookCommandObjects enum)
    look
}

private enum LookCommandObjects
{
    nothing = 0,
    food,
    spike,
    agent
}

public struct Flags
{
public:
    bool getGreater() => cast(bool) flags & greater;
    bool getEquals() => cast(bool) flags & equals;
    bool getLess() => cast(bool) flags & less;
    bool getCarry() => cast(bool) flags & carry;

    void setGreater(bool value) { flags = value; }
    void setEquals(bool value) { flags = (value << 1); }
    void setLess(bool value) { flags = (value << 2); }
    void setCarry(bool value) { flags = (value << 3); }

private:
    ubyte flags;
    enum ubyte greater = 1;
    enum ubyte equals = 2;
    enum ubyte less = 4;
    enum ubyte carry = 8;
}

public struct Agent
{
    public:
    float energy;

    /// Program counter lice in VMs lol
    int pc;

    /// A register tosave information
    NumericInstruction register;

    /// Compare instruction flags
    Flags flags;    
    
    /// Agent's genome
    // 64 is the default genome size, but we set 65 because at some reason dynamic allocations begin
    // even if the static storage size == genome size
    Array!(Instruction, 65) genome; 
}

@AddAtStart
public class SpawnAgentSystem : BaseSystem
{
    mixin CreateMethod!SpawnAgentSystem;
    private enum float baseSpawnFrequency = 0.01;

    public override void onCreated()
    {
        for(int y = 0; y < gsic.yMapSize; y++)
        {
            for (int x = 0; x < gsic.xMapSize; x++)
            {
                auto object = map.getAtPosition([x, y]);   
                if (!object.hasComponent!Agent() && uniform01() <= gsc.agentSpawnFrequency * baseSpawnFrequency)
                {
                    Agent agent;
                    agent.genome.reserve(gat.genomeSize);

                    foreach(i; 0..gat.genomeSize)
                    {
                        int maxInstruction = gat.maxInstructionValue;
                        if(maxInstruction < 1) maxInstruction = Instruction.max + 1;

                        auto raw = uniform(0, maxInstruction);
                        agent.genome ~= cast(Instruction) raw;
                    }

                    agent.energy = gat.baseEnergy;

                    object.addComponent!Agent(agent);
                }
            }
        }  
    }

    public override void update()
    {
    }
}

@AddAtStart
public class AgentSystem : ObjectSystem!Agent
{
    mixin CreateMethod!AgentSystem;
    mixin OnComponentRemoveCallback!Agent;
    
    private enum agentColor = colorFromHEX!(0xF4F078);

    public this()
    {
        color = agentColor;
    }

    protected override void cleanUp(SimObject object)
    {
        object.getComponent!Agent().genome.free();
    }

    public override void updateObject(ref Agent agent, SimObject object)
    {
        enum float energyClamp = 0.1;
        if(agent.energy < energyClamp) agent.energy = energyClamp;
        agent.energy -= gat.starveEnergy;

        if(agent.energy <= 0) 
        {
            object.removeComponent!Agent();
            return;
        }

        executeGenome(agent, object);
    }

    private void mutate(ref Agent agent)
    {
        int mutationsCount = uniform!"[]"(gat.minMutationsCount, gat.maxMutationsCount);

        foreach (mutation; 0..mutationsCount)
        {
            int maxInstruction = gat.maxInstructionValue;
            if(maxInstruction < 1) maxInstruction = Instruction.max + 1;
                        
            int index = uniform(0, cast(int) agent.genome.length);
            agent.genome[index] = cast(Instruction) uniform(0, maxInstruction);
        }
    }

    private void executeGenome(ref Agent agent, SimObject object)
    {        
        ref int pc = agent.pc;

        void boundPC()
        {
            if(pc < 0) pc = 0;
            pc %= gat.genomeSize;
        }

        /// Add program counter and return its new value
        /// Params:
        ///   value = added to counter value
        /// Returns: new pc value
        int addPC(int value)
        {
            pc += value;
            boundPC();

            return pc;
        }

        for(int i = 0; i < gat.maxExecutedCommands; i++)
        {
            auto instruction = agent.genome[addPC(1)];
            switch(instruction)
            {
                case Instruction.ret:
                    // Stop executing this genome.
                    return;

                case Instruction.walk:
                    // Mod by 3 because we have 3 neighbor cells at each side:
                    //
                    // 0 [0][1][2]
                    // 1 [0][x][2] <- x is object!
                    // 2 [0][1][2]
                    //
                    // Values in genome can be higher, than 2, so we using mod here.
                    int[2] position;
                    position[0] = cast(int) agent.genome[addPC(1)];
                    position[1] = cast(int) agent.genome[addPC(1)];

                    int[2] relativePosition;
                    relativePosition[] = position[] % 3;

                    SimObject other = map.getNeighbors(object)[relativePosition[1]][relativePosition[0]];

                    if(other.hasComponent!Agent())
                    {
                        return;
                    }
                    else if(other.hasComponent!Food())
                    {
                        return;
                    }
                    else if(other.hasComponent!Spike())
                    {
                        return;
                    }

                    map.swap(object, other);

                    agent.energy -= gat.walkEnergyCost;

                    // Made movement == our turn is over.
                    return;

                case Instruction.jump:
                    // add 1 because address is saved at next command
                    addPC(1);
                    // now jump to new address
                    pc = agent.genome[pc];
                    boundPC();
                    break;
                case Instruction.divide:
                    NumericInstruction childPC = agent.genome[addPC(1)];

                    auto neighbors = map.getNeighbors(object);

                    foreach (ref row; neighbors)
                    {
                        foreach (ref neighbor; row)
                        {   
                            if(neighbor.hasComponent!Agent) continue;
                        
                            agent.energy /= 2;

                            //We can't copy parent because child's genome could have references on the same storage
                            //(if genome size > 64). Then we should set child's genome init value and copy parent's values
                            //in it, but that's too unoptimized. Just copy genome is simpler
                            Agent child;
                            child.energy = agent.energy;
                            child.flags = agent.flags;
                            child.register = agent.register;
                            child.genome.reserve(gat.genomeSize);
                            child.pc = childPC;

                            foreach(j; 0..gat.genomeSize)
                            {
                               child.genome ~= agent.genome[j];
                            }
                            
                            mutate(child);

                            neighbor.addComponent!Agent(child);
                            goto foreachBreak;
                        }
                    }
                    foreachBreak:
                    return;

                case Instruction.apoptose:
                    object.removeComponent!Agent();
                    return;

                case Instruction.set:
                    NumericInstruction address = agent.genome[addPC(1)]  % agent.genome.length;
                    NumericInstruction value = agent.genome[addPC(1)];
                    agent.genome[address] = cast(Instruction) value;
                    break;
                
                case Instruction.eat:
                    int[2] position;
                    position[0] = cast(int) agent.genome[addPC(1)];
                    position[1] = cast(int) agent.genome[addPC(1)];

                    int[2] relativePosition;
                    relativePosition[] = position[] % 3;

                    SimObject other = map.getNeighbors(object)[relativePosition[1]][relativePosition[0]];

                    pragma(inline, true)
                    void tryRemoveAndAddEnergy(T)(float energy)
                    {                        
                        if(other.hasComponent!T())
                        {
                            other.removeComponent!T();
                            agent.energy += energy;
                        }
                    }                    

                    tryRemoveAndAddEnergy!Agent(gat.cannibalismEnergy);
                    tryRemoveAndAddEnergy!Food(gat.foodEnergy);
                    tryRemoveAndAddEnergy!Spike(-gat.spikeEnergyDamage);
                    return;
                
                case Instruction.compare:
                    NumericInstruction value = agent.genome[addPC(1)];

                    ptrdiff_t result = agent.register - value;
                    enum size_t shift = result.sizeof * 8L - 1L;
                    
                    bool signBit = cast(bool)(result >> shift);

                    agent.flags.setCarry(signBit);
                    if(result > value)
                    {
                        agent.flags.setGreater(true);
                    }
                    else if(result == value)
                    {
                        agent.flags.setEquals(true);
                    }
                    else
                    {
                        agent.flags.setLess(true);
                    }
                    break;

                case Instruction.jumpCarry:
                    // Inconditional jump would be agent.genome[addPC(1)].
                    // Carry flag is 0 or 1 (because that's a flag),
                    // so to avoid a huge and long if(agent.flags.getCarry())
                    // we add carry flag to pc.
                    // We either jump to instruction at next or jump to THIS ADDRESS and continue executing!
                    pc = agent.genome[addPC(cast(int) agent.flags.getCarry)];
                    break;

                case Instruction.jumpGreater:
                    // ditto
                    pc = agent.genome[addPC(cast(int) agent.flags.getGreater)];
                    break;
                
                case Instruction.jumpEquals:
                    // ditto
                    pc = agent.genome[addPC(cast(int) agent.flags.getEquals)];
                    break;

                case Instruction.jumpLess:
                    // ditto
                    pc = agent.genome[addPC(cast(int) agent.flags.getLess)];
                    break;

                case Instruction.look:
                    int[2] position;
                    position[0] = cast(int) agent.genome[addPC(1)];
                    position[1] = cast(int) agent.genome[addPC(1)];

                    int[2] relativePosition;
                    relativePosition[] = position[] % 3;

                    SimObject other = map.getNeighbors(object)[relativePosition[1]][relativePosition[0]];

                    if(other.hasComponent!Agent()) agent.register = LookCommandObjects.agent;
                    else if(other.hasComponent!Food()) agent.register = LookCommandObjects.food;
                    else if(other.hasComponent!Spike()) agent.register = LookCommandObjects.spike;
                    else agent.register = LookCommandObjects.agent;

                    break;

                default:
                    pc = cast(int) instruction;
                    boundPC();
                    break;
            }
        }
    }
}