// Hash_Table which never moves its contents.  Trades performance for reliability.

#module_parameters (
    SIZE_MIN := 32,
    LOGGING := false
);


Stable_Table :: struct (Key_Type: Type, Value_Type: Type,
                 given_hash_function: (Key_Type) -> u32 = null,
                 given_compare_function: (Key_Type, Key_Type) -> bool = null,
                 LOAD_FACTOR_PERCENT: u32 = 70,
                 REFILL_REMOVED := true
                ) {
    Table_Type :: Hash_Table.Table(Key_Type, Value_Type, given_hash_function, given_compare_function, LOAD_FACTOR_PERCENT, REFILL_REMOVED);
    tables: [..] *Table_Type;
}

init :: (using stable_table: *Stable_Table, slots_to_allocate: s64 = 0) {
    if stable_table.tables.count == 0
        array_add(*stable_table.tables, New(stable_table.Table_Type));

    if slots_to_allocate == 0  slots_to_allocate = SIZE_MIN;
    Hash_Table.init(stable_table.tables[0], slots_to_allocate);
}

table_find_pointer :: (stable_table: *Stable_Table, key: stable_table.Key_Type) -> *stable_table.Value_Type {
    for table: stable_table.tables {
        found_pointer := Hash_Table.table_find_pointer(table, key);
        if found_pointer  return found_pointer;
    }
    return null;
}

table_add :: (stable_table: *Stable_Table, key: stable_table.Key_Type, value: stable_table.Value_Type) -> *stable_table.Value_Type {
    new_slots_allocated := SIZE_MIN;
    if stable_table.tables.count {
        table := stable_table.tables[stable_table.tables.count - 1];
        new_slots_allocated = table.allocated * 2;
        // Add to the current table if it won't trigger a resize;
        // (This if should be the negation of the check used in Hash_Table)
        if !((table.slots_filled + 1)*100 >= table.allocated*table.LOAD_FACTOR_PERCENT) {
            allocated := table.allocated;
            result := Hash_Table.table_add(table, key, value);
            assert(table.allocated == allocated, "The subtable has expanded, but the point of this module is for that to never happen!\n");
            return result;
        }
    }

    table := New(stable_table.Table_Type);
    array_add(*stable_table.tables, table);
    Hash_Table.init(table, new_slots_allocated);
    #if LOGGING  print("Growing table % [new table count: %, new table size: %]\n", stable_table, stable_table.tables.count, new_slots_allocated);
    return Hash_Table.table_add(table, key, value);
}

find_or_add :: (stable_table: *Stable_Table, key: stable_table.Key_Type) -> (entry: *stable_table.Value_Type, newly_added: bool) {
    value := table_find_pointer(stable_table, key);
    if value  return value, false;

    new_value: stable_table.Value_Type;
    value = table_add(stable_table, key, new_value);
    return value, true;
}

table_remove :: (stable_table: *Stable_Table, key: stable_table.Key_Type) -> (success: bool, value: stable_table.Value_Type) {
    for table: stable_table.tables {
        success, value := Hash_Table.table_remove(table, key);
        if success  return true, value;
    }

    dummy: stable_table.Value_Type;
    return false, dummy;
}


#scope_file

Hash_Table :: #import "Hash_Table";
#import "Basic";