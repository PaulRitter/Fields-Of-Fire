#define IDX_OFFSET_X 1
#define IDX_OFFSET_Y 2

/obj/structure/multitile
    //config vars
    var/list/offsets = list() // list of all tiles which need to be impassable

    //system vars
    var/list/strucs = list() //list of all the structures we spawned

/obj/structure/multitile/New()
    ..()
    for(var/list/offset in offset)
        var/obj/structure/S = new /obj/structure()
        var/newloc = locate(loc.x + offset[IDX_OFFSET_X], loc.y + offset[IDX_OFFSET_Y], loc.z)
        S.Move(newloc)
        strucs += S

/obj/structure/multitile/Destroy()
    ..()
    for(var/children in strucs)
        qdel(children)
    strucs.len = 0

/obj/structure/multitile/rectangle
    var/sizeX = 0
    var/sizeY = 0

/obj/structure/multitile/rectangle/New()
    offsets.len = 0
    for(var/x = 0; x <= sizeX; x++)
        for(var/y = 0; y <= sizeY; y++)
            if(!x && !y)
                continue
            offsets += list(list(x, y))
    ..()
