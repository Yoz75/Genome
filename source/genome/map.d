module genome.map;

import genome.simobject;
import genome.settings.config;

/// Global map instance
Map map;

/// Map of the simulation
public struct Map
{
    private SimObject[][] field;
    private SimObject[][] tempField;

    private World fieldWorld, tempFieldWorld;

    /// Get object at specific position
    /// Params:
    ///   position = the position to get object at
    /// Returns: object at position
    public ref SimObject getAtPosition(int[2] position)
    {
        position = boundPosition(position);
        return field[position[1]][position[0]];
    }

    /// Get neighbors of the object at specific position
    /// Params:
    ///   object = trhe object to get neighbors of
    /// Returns: object's neighbors
    public SimObject[3][3] getNeighbors(SimObject object)
    {
        int[2] pos = object.position;

        SimObject[3][3] neighbors;

        for (int dy = -1; dy <= 1; dy++)
        {
            for (int dx = -1; dx <= 1; dx++)
            {
                int resultX = pos[0] + dx;
                int resultY = pos[1] + dy;

                // We add 1 to dx and dy to convert its ranges from -1..1 to 0..2 (range of result array)
                neighbors[dy + 1][dx + 1] = getAtPosition([resultX, resultY]);
            }
        }

        return neighbors;
    }

    /// Init map
    public void initMe()
    {
        fieldWorld = World.create();
        tempFieldWorld = World.create();

        field = new SimObject[][gsic.yMapSize];

        foreach(y, ref col; field)
        {
            col = new SimObject[gsic.xMapSize];
            foreach(x, ref object; col)
            {
                object = SimObject.create(&fieldWorld);
                object.position = [cast(int) x, cast(int) y];
            }
        }

        tempField = new SimObject[][gsic.yMapSize];

        foreach(y, ref col; tempField)
        {
            col = new SimObject[gsic.xMapSize];
            foreach(x, ref object; col)
            {
                object = SimObject.create(&tempFieldWorld);
                object.position = [cast(int) x, cast(int) y];
            }
        }
    }

    /// Swap a and b correctly
    /// Params:
    ///   a = a
    ///   b = b
    public void swap(ref SimObject a, ref SimObject b)
    {
        int[2] posA = boundPosition(a.position);
        int[2] posB = boundPosition(b.position);

        a.position = posB;
        b.position = posA;

        tempField[posA[1]][posA[0]] = b;
        tempField[posB[1]][posB[0]] = a;
    }

    public void updateFields()
    {
        /*
            we "juggle" with fields, then copy new field's values into temp field 
            (this shit is done to avoid GC allocations of new array)
        */
        auto temp = field;
        field = tempField;
        tempField = temp;

        foreach (y, col; tempField)
        {
            foreach(x, ref object; col)
            {
                object = field[y][x];
            }
        }
    }

    pragma(inline, true)
    private int[2] boundPosition(int[2] position)
    {
        if (position[0] < 0) position[0] = gsic.xMapSize - 1;
        if (position[1] < 0) position[1] = gsic.yMapSize - 1;

        if (position[0] >= gsic.xMapSize) position[0] = 0;
        if (position[1] >= gsic.yMapSize) position[1] = 0;

        return position;
    }
}