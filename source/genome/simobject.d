module genome.simobject;

import genome.map : map;
import genome.settings.config;
import genome.simulation : Simulation;
import std.bitmanip;

/// List of all systems in the simulation
BaseSystem[] systems;

alias Id = size_t;
alias onRemoveAction = void delegate(SimObject entity);

/// Component pool for entities in the simulation
public struct ComponentPool(T)
{
    public static ComponentPool!T instance;
    private T[][] data;
    //is entity [i] has this component or not?
    private BitArray[] entitiesHasTable;

    private onRemoveAction[] onRemoveDelegates;

    /// Add component to entity
    /// Params:
    ///   entity = the entity
    ///   value = the value of added component
    public void addComponent(SimObject entity, T value)
    {
        tryExtendData(entity);

        data[entity.world.id][entity.id] = value;
        entitiesHasTable[entity.world.id][entity.id] = true;
    }


    /// Remove component from entity. If entity already doesn't have this component, nothing will happen
    /// Params:
    ///   entity = the entity
    public void removeComponent(SimObject entity)
    {
        tryExtendData(entity);
        data[entity.world.id][entity.id] = T.init;
        entitiesHasTable[entity.world.id][entity.id] = false;

        foreach (onRemove; onRemoveDelegates)
        {
            onRemove(entity);
        }
    }
    
    public void addOnRemoveAction(scope onRemoveAction action)
    {
        onRemoveDelegates ~= action;
    }

    /// Get component for entity
    /// Params:
    ///   entity = the entity
    /// Returns: 
    public ref T getComponent(SimObject entity)
    {
        tryExtendData(entity);

        return data[entity.world.id][entity.id];
    }

    public bool hasComponent(SimObject entity)
    {
        tryExtendData(entity);
        return entitiesHasTable[entity.world.id][entity.id];
    }

    /// Try to extend data and has table if they are too short
    /// (this name is bad, it it neetds to be renamed)
    /// Params:
    ///   entity = the entity
    pragma(inline, true)
    private void tryExtendData(SimObject entity)
    {
        if (entity.world.id >= entitiesHasTable.length)
        {
            entitiesHasTable.length = entity.world.id + 1;
        }
        if (entity.world.id >= data.length)
        {
            data.length = entity.world.id + 1;
        }

        ref BitArray worldHasTable = entitiesHasTable[entity.world.id];
        ref T[] worldDataTable = data[entity.world.id];

        if (entity.id >= worldHasTable.length)
        {
            entitiesHasTable[entity.world.id].length = entity.id + 1;
        }
        if (entity.id >= worldDataTable.length)
        {
            data[entity.world.id].length = entity.id + 1;
        }
    }
}

/// Entity in the simulation (ECS)
public struct SimObject
{
    /// Identificator, used for components
    public Id id;
    /// Object's world
    public World* world;

    /// Object position
    public int[2] position; 

    public static SimObject create(World* world)
    {
        return SimObject(world.totalEntities_++, world);
    }   

pragma(inline, true):
    /// Shortcut for ComponentPool!T.addComponent. See ComponentPool.addComponent
    public void addComponent(T)(T value)
    {
        ComponentPool!T.instance.addComponent(this, value);
    }    

    /// Shortcut for ComponentPool!T.getComponent. See ComponentPool.getComponent
    public ref T getComponent(T)()
    {
        return ComponentPool!T.instance.getComponent(this);
    }

    /// Shortcut for ComponentPool!T.hasComponent. See ComponentPool.hasComponent
    public bool hasComponent(T)()
    {
        return ComponentPool!T.instance.hasComponent(this);
    }

    /// Shortcut for ComponentPool!T.removeComponent. See ComponentPool.removeComponent
    public void removeComponent(T)()
    {
        return ComponentPool!T.instance.removeComponent(this);
    }

pragma(inline):
}

/// Empty struct to use as a component if you don't need any data in it or you want only call onCreated method
public struct None
{
    
}

/// Use this attribute on your system if you want to add it at start of the simulation. Your system MUST mix in CreateMethod
public struct AddAtStart
{

}

/// Base class for systems. Needed only beause System(T) is tenplate class
public abstract class BaseSystem
{
    /// Mix in this template if you need to access this system from others
    /// Params:
    ///   TSelf = your system type
    protected mixin template MakeSingleton(TSelf)
    {
        public static TSelf instance;

        public this()
        {
            instance = this;
        }
    }

    /// Mix in this template to add a static TSelf create() method.
    /// Params:
    ///   TSelf = your system type
    protected mixin template CreateMethod(TSelf)
    {
        /// Called when system instance is created trough create method of CreateMethod mixin
        import genome.simulation : Simulation;
        public static TSelf create()
        {
            auto system = new TSelf();

            systems ~= system;

            system.onCreated();

            return system;
        }
    }

    /// Current simulation pointer (for some functions, e.g. restarting etc) 
    ///(at some reason I can't declare ref field with D 2.111 :\)
    public Simulation* simulation;

    /// Update system for each component
    public abstract void update();

    public void destroy()
    {
        onDestroyed();
    }

    protected void onDestroyed()
    {
        //nothing here
    }

    public void onCreated()
    {
        //nothing here
    }
}

/// Real base class for all systems. T is component type that this system works with
public abstract class System(T) : BaseSystem
{    
    /// Mix in this, to call onRemove, when T removed from object.
    /// This thing uses parameterless constructor.
    public mixin template OnComponentRemoveCallback(T)
    {
        public this()
        {
            ComponentPool!T.instance.addOnRemoveAction(&onRemove);
        }
    }

    public override void update()
    {
        foreach (int y; 0 .. gsic.yMapSize)
        {
            foreach (int x; 0 .. gsic.xMapSize)
            {
                ref SimObject object = map.getAtPosition([x, y]);

                if(object.hasComponent!T()) updateComponent(object.getComponent!T(), object);
            }
        }
    }
    
    protected override void onDestroyed()
    {
        ComponentPool!T.instance.entitiesHasTable.length = 0;
    }

    /// Update component
    protected abstract void updateComponent(ref T component, SimObject object);

    public void onRemove(SimObject object)
    {
        //nothing
    }
}

/// Base class for main object's systems. 
public abstract class ObjectSystem(T) : System!(T)
{
    import genome.rendering;

    mixin OnComponentRemoveCallback!T;

    protected Color color;

    public final override void onRemove(SimObject object)
    {
        object.getComponent!Renderable.color = Color(0, 0, 0);
        cleanUp(object);
    }

    protected final override void updateComponent(ref T component, SimObject object)
    {
        object.getComponent!Renderable().color = color;
        updateObject(component, object);
    }

    /// calls in onRemove
    protected void cleanUp(SimObject)
    {
        //nothing
    }

    protected abstract void updateObject(ref T component, SimObject object);
}

public struct World
{
    public static World create()
    {
        static Id lastId;

        return World(lastId++);
    }

    // private, but everything is public within a single module
    private size_t totalEntities_;
    private Id id_;

    public @property size_t totalEntities() => totalEntities_;
    public @property Id id() => id_;
}