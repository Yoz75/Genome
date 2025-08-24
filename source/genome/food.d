module genome.food;

import genome.simobject;
import genome.map;
import genome.rendering;
import genome.settings.config;
import genome.agent : Agent;
import genome.spike : Spike;
import std.random;

public struct Food
{
public:
    int aliveFrames;
}

@AddAtStart 
public class SpawnFoodSystem : BaseSystem
{
    mixin CreateMethod!SpawnFoodSystem;
    enum float baseSpawnFrequency = 0.001;

    public override void update()
    {
        for(int y = 0; y < gsic.yMapSize; y++)
        {
            for (int x = 0; x < gsic.xMapSize; x++)
            {
                auto object = map.getAtPosition([x, y]);   
                if (canSpawnFood(object) && uniform01() <= gsc.foodSpawnFrequency * baseSpawnFrequency)
                {
                    object.addComponent!Food(Food.init);
                }
            }
        }
    }

    private bool canSpawnFood(SimObject object)
    {
        if(object.hasComponent!Agent() || object.hasComponent!Food() || object.hasComponent!Spike())
        {
            return false;
        }

        return true;
    }
}

@AddAtStart
public class FoodSystem : ObjectSystem!Food
{
    mixin CreateMethod!FoodSystem;
    mixin OnComponentRemoveCallback!Food;

    private enum Color foodColor = colorFromHEX!0x0CAE00;   

    public this()
    {
        color = foodColor;
    }

    protected override void updateObject(ref Food food, SimObject object)
    {
        if(food.aliveFrames >= gsc.maxFoodAliveFrames) object.removeComponent!Food;

        food.aliveFrames++;
    }
}