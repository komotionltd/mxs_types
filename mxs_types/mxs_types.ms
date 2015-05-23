/***The MIT License (MIT)

Copyright (c) 2015 Christoph Buelter (www.cbuelter.de)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.***/



struct mxs_dict (
    /***Represents a mapping of keys to values.

    Anything can be used as a key or value, e.g. scene objects,
    materials, color values or controllers, making it very versatile.

    Supports sorting by key/value if keys/values are all of the
    same comparable type (e.g. all strings or numbers).

    Note: This is not a 'real' hash table, just parallel arrays,
    resulting in low performance when used with many items.

    The interface is loosely based on Python's dict API.

    ***/

    -- Public for tests and convenience.
    -- Do not modify directly.
    public
    _keys = #(),
    _values = #(),

    -- Static methods.

    public
    fn fromkeys keys default:undefined = (
        /***Returns a dict instance build from the
        given keys and the supplied default value.***/
        local new_dict = mxs_dict()
        new_dict._keys = keys
        new_dict._values = for key in keys collect default
        new_dict
    ),

    -- Instance methods.

    public
    fn has_key key = (
        /***Returns True if the key is part
        of the dict, False otherwise.***/
        local idx = findItem this._keys key
        idx != 0
    ),

    public
    fn has_value val = (
        /***Returns True if the value is part
        of the dict, False otherwise.***/
        local idx = findItem this._values val
        idx != 0
    ),

    public
    fn get key default:undefined = (
        /***Returns the value that belongs to the given key
        or the supplied default, if the key does not exist.***/
        for i = 1 to this._keys.count do
            if this._keys[i] == key do
                return this._values[i]
        default
    ),

    public
    fn keys = (
        /***Returns a list of keys.***/
        this._keys
    ),

    public
    fn values = (
        /***Returns a list of values.***/
        this._values
    ),

    public
    fn items = (
        /***Returns a list of key-value tuples.***/
        for i = 1 to this._keys.count collect
            #(this._keys[i], this._values[i])
    ),

    public
    fn clear = (
        /***Resets the internal key and value
        arrays, thus emptying the dict.***/
        this._keys = #()
        this._values = #()
    ),

    public
    fn add key val = (
        /***Adds a new key-value pair if the key is new.
        Updates the value for the existing key otherwise.***/
        local idx = findItem this._keys key
        if idx != 0 then
            this._values[idx] = val
        else (
            append this._keys key
            append this._values val
        )
    ),

    public
    fn set_ key val = (
        /***Can be used as an alias for add().

        set() unfortunately is a reserved MXS keyword.

        ***/
        this.add key val
    ),

    public
    fn copy = (
        /***Returns a shallow copy of this dict.

        If the keys or values are referenced datatypes,
        these references are kept intact, no copies are made.

        ***/
        local new_dict = mxs_dict()
        new_dict._keys = for key in this._keys collect key
        new_dict._values = for val in this._values collect val
        new_dict
    ),

    public
    fn pop key default: = (
        /***Returns the value for the given key,
        effectively removing this item from the dict.

        If a default value is supplied, this is
        returned instead of the actual value.

        Returns undefined if the key does not exist.

        ***/
        local idx = findItem this._keys key
        if idx != 0 do (
            deleteItem this._keys idx
            local val = this._values[idx]
            deleteItem this._values idx
            if default != unsupplied do
                return default
            return val
        )
        undefined
    ),

    public
    fn popitem = (
        /***Returns a random key-value tuple from the
        dict, effectively removing this item from it.***/
        if this._keys.count > 0 do (
            local idx = random 1 this._keys.count
            local item = #(this._keys[idx], this._values[idx])
            deleteItem this._keys idx
            deleteItem this._values idx
            return item
        )
        undefined
    ),

    public
    fn update dict_ = (
        /***Updates this dict in-place with the supplied one.

        New key-value pairs are added, existing ones are updated.
        Can be used e.g. to merge two dicts into one.

        ***/
        local input_keys = dict_.keys()
        local input_values = dict_.values()
        for i = 1 to input_keys.count do
            this.add input_keys[i] input_values[i]
    ),

    public
    fn _sort_by item1 item2 item_index:1 reversed:False = (
        /***Used to sort by key or value
        based on the given items.***/
        local smaller = if reversed then 1 else -1
        local bigger = if reversed then -1 else 1

        local v1 = item1[item_index]
        local v2 = item2[item_index]

        case of (
            (v1 < v2) : smaller
            (v1 > v2) : bigger
            default : 0
        )
    ),

    public
    fn _update_arrays items = (
        /***As sorting is based on items, this function
        empties and rebuilds the _keys and _values arrays.***/
        this.clear()
        for i = 1 to items.count do (
            this._keys[i] = items[i][1]
            this._values[i] = items[i][2]
        )
    ),

    public
    fn sort_by_key reversed:False = (
        /***In-place sorting of the dict's items based
        on the alphabet-/numer-ical order of the keys.***/
        local items = this.items()
        try (
            qsort items this._sort_by item_index:1 reversed:reversed
            this._update_arrays items
        )
        catch (
            format "[ERROR] %\n" ("Could not sort dict by key, " + \
                                  "keys are not of comparable type.")
            throw
        )
    ),

    public
    fn sort_by_value reversed:False = (
        /***In-place sorting of the dict's items based
        on the alphabet-/numer-ical order of the values.***/
        local items = this.items()
        try (
            qsort items this._sort_by item_index:2 reversed:reversed
            this._update_arrays items
        )
        catch (
            format "[ERROR] %\n" ("Could not sort dict by value, " + \
                                  "values are not of comparable type.")
            throw
        )
    )
)


struct mxs_defaultdict (
    /***Similar to the collections.defaultdict in Python,
    this dict gets a factory function as its first argument
    to create and add values for unknown keys on the fly.

    The rest of the API works as in mxs_dict.

    It is useful for manipulating values on the fly that
    can be modified in-place, like arrays or custom struct
    instances, for collecting or counting objects.

    Example:

    fn list = #()
    d = mxs_defaultdict list
    append (d.get "foo") 123
    append (d.get "foo") 456
    append (d.get "foo") 789
    d.get "foo"
    >>> #(123, 456, 789)

    ***/
    public
    default_factory,

    private
    _dict = mxs_dict(),

    public
    _keys = this._dict._keys,
    _values = this._dict._values,

    -- Override the get() method while delegating all others.
    public
    fromkeys = this._dict.fromkeys,
    has_key = this._dict.has_key,
    has_value = this._dict.has_value,

    public
    fn get key  = (
        /***Unknown keys will trigger insertion of
        the value returned by default_factory.***/
        if this.default_factory != undefined and \
                not (this._dict.has_key key) do (
            local val = this.default_factory()
            this.add key val
            return val
        )

        this._dict.get key
    ),

    public
    keys = this._dict.keys,
    values = this._dict.values,
    items = this._dict.items,
    clear = this._dict.clear,
    add = this._dict.add,
    set_ = this._dict.set_,
    copy = this._dict.copy,
    pop = this._dict.pop,
    popitem = this._dict.popitem,
    update = this._dict.update,
    sort_by_key = this._dict.sort_by_key,
    sort_by_value = this._dict.sort_by_value
)


struct mxs_set (
    /***Represents a collection of unique elements.

    Offers operations like union, difference, intersection etc.

    A set can be constructed simply like:
        mxs_set()
    Or with an array as its first argument to start with:
        mxs_set #(...)

    Note: Elements can have any type, but be aware that due
    to MAXScript limitations some values can not be tested
    for uniqueness, e.g. when comparing arrays.

    The interface is loosely based on Python's set API.

    ***/

    public
    _elements,  -- Initialized in event handler.

    -- Static methods.

    public
    fn from_array array_ = (
        /***Returns a new set based on the given array.***/
        mxs_set array_
    ),

    -- Instance methods.

    public
    fn elements = (
        this._elements
    ),

    public
    fn add element = (
        /***Add an element to a set.
        This has no effect if the element is already present.***/
        appendIfUnique this._elements element
    ),

    public
    fn set_elements elements_ = (
        /***Set elements from given list.
        Elements will only contain unique items afterwards.***/
        this._elements = #()
        for element in elements_ do
            this.add element
    ),

    private
    fn _discard_by_index idx = (
        if idx != 0 do
            deleteItem this._elements idx
    ),

    public
    fn discard element = (
        /***Remove an element from a set if it is a member.
        If the element is not a member, do nothing.***/
        local idx = findItem this._elements element
        this._discard_by_index idx
    ),

    public
    fn clear = (
        /***Remove all elements from this set.***/
        this._elements = #()
    ),

    public
    fn copy = (
        /***Return a shallow copy of a set.***/
        mxs_set this._elements
    ),

    public
    fn difference set_ = (
        /***Return the difference of this set and another as a new set.
        (i.e. all elements that are in this set but not the other.)***/
        local differing = #()
        for element_1 in this.elements() do (
            local found = false
            for element_2 in set_.elements() while not found do (
                if element_1 == element_2 do
                    found = true
            )
            if not found do
                append differing element_1
        )
        mxs_set differing
    ),

    public
    fn difference_update set_ = (
        /***Remove all elements of another set from this set.***/
        local diff_set = this.difference set_
        this._elements = diff_set.elements()
    ),

    public
    fn intersection set_ = (
        /***Return the intersection of this set and another as a new set.
        (i.e. elements that are common to both sets.)***/
        local intersecting = #()
        for element_1 in this.elements() do (
            local found = false
            for element_2 in set_.elements() while not found do (
                if element_1 == element_2 do
                    found = true
            )
            if found do
                append intersecting element_1
        )
        mxs_set intersecting
    ),

    public
    fn intersection_update set_ = (
        /***Update a set with the intersection of itself and another.***/
        local intersect_set = this.intersection set_
        this._elements = intersect_set.elements()
    ),

    public
    fn isdisjoint set_ = (
        /***Return true if two sets have a null intersection.***/
        local intersect_set = this.intersection set_
        (intersect_set.elements()).count == 0
    ),

    public
    fn issubset set_ = (
        /***Report whether another set contains this set.***/
        for element_1 in this.elements() do (
            local found = false
            for element_2 in set_.elements() do (
                if element_1 == element_2 do
                    found = true
            )
            if not found do
                return false
        )
        true
    ),

    public
    fn issuperset set_ = (
        /***Report whether this set contains another set.***/
        for element_2 in set_.elements() do (
            local found = false
            for element_1 in this.elements() do (
                if element_2 == element_1 do
                    found = true
            )
            if not found do
                return false
        )
        true
    ),

    public
    fn pop = (
        /***Remove and return an arbitrary set element.
        Return undefined if the set is empty.***/
        local count_ = this._elements.count
        if count_ > 0 do (
            local idx = random 1 count_
            local element = this._elements[idx]
            this._discard_by_index idx
            return element
        )
        undefined
    ),

    private
    fn _is_in set_ item_ = (
        local elements_ = set_.elements()
        local idx = findItem elements_ item_
        idx != 0
    ),

    public
    fn symmetric_difference set_ = (
        /***Return the symmetric difference of two sets as a new set.
        (i.e. all elements that are in exactly one of the sets.)***/
        local only_in_this = #()
        for element_1 in this.elements() do (
            if not this._is_in set_ element_1 do
                append only_in_this element_1
        )

        local only_in_that = #()
        for element_2 in set_.elements() do (
            if not this._is_in this element_2 do
                append only_in_that element_2
        )
        local symmetric = only_in_this + only_in_that
        mxs_set symmetric
    ),

    public
    fn symmetric_difference_update set_ = (
        /***Update a set with the symmetric
        difference of itself and another.***/
        local symmetric_set = this.symmetric_difference set_
        this._elements = symmetric_set.elements()
    ),

    public
    fn union set_ = (
        /***Return the union of sets as a new set.
        (i.e. all elements that are in either set.)***/
        local united = this.elements() + set_.elements()
        mxs_set united
    ),

    public
    fn update set_ = (
        /***Update a set with the union of itself and another.***/
        local union_set = this.union set_
        this._elements = union_set.elements()
    ),

    public
    fn update_from_array array_ = (
        /***Update a set with the union of itself and a new set
        (which is created based on the given array).***/
        local set_ = mxs_set array_
        this.update set_
    ),

    public
    fn to_array = (
        /***Return the set content as an array.***/
        this._elements
    ),

    on create do (
        -- Handle array as optional first argument of constructor.
        if this._elements != undefined then
            this._elements = makeUniqueArray this._elements
        else
            this._elements = #()
    )
)

