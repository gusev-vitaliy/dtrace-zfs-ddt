#!/usr/sbin/dtrace -s
#pragma D option dynvarsize=16m
#pragma D option quiet

/*
 * Meausure DDT spent time during ddt_lookup
 *
 */

::BEGIN,
::END
{
        self->count = 0;
}

ddt_lookup:entry
{
        self->ddte = 1;
}

ddt_lookup:return
{
        self->ddte = 0;
}

avl_find:entry,
avl_insert:entry,
ddt_stat_generate:entry
/self->ddte == 1/
{
	self->vstart[probefunc] = vtimestamp;
	self->start[probefunc] = timestamp;
}

ddt_enter:entry
/self->ddte == 1/
{
	self->vstart["ddt_exit"] = vtimestamp;
	self->start["ddt_exit"] = timestamp;
}

dde_enter:entry
/self->ddte == 1/
{
	self->vstart["dde_exit"] = vtimestamp;
	self->start["dde_exit"] = timestamp;
}

ddt_lookup:entry,
ddt_alloc:entry,
ddt_sync_table:entry,
ddt_sync_entry:entry,
ddt_zap_lookup:entry,
ddt_zap_remove:entry,
ddt_zap_update:entry
{
	self->vstart[probefunc] = vtimestamp;
	self->start[probefunc] = timestamp;
}

avl_find:return,
avl_insert:return,
ddt_stat_generate:return,
ddt_exit:return,
dde_exit:return,
ddt_lookup:return,
ddt_alloc:return,
ddt_sync_table:return,
ddt_sync_entry:return,
ddt_zap_lookup:return,
ddt_zap_remove:return,
ddt_zap_update:return
/self->vstart[probefunc]/
{
        this->oncpu = vtimestamp - self->vstart[probefunc];
        this->onsys = timestamp - self->start[probefunc];

        @oncpu[probefunc] = sum(this->oncpu);
        @onsys[probefunc] = sum(this->onsys);
        @calls[probefunc] = count();

        self->vstart[probefunc] = 0;
	self->start[probefunc] = 0;
}

profile:::tick-10s
{
	normalize(@oncpu, 1000000);
	normalize(@onsys, 1000000);
	trunc(@oncpu, 20);
	trunc(@onsys, 20);
	trunc(@calls, 20);
	
	self->count++;
	printf("\n\n\n\n\nSTEP %d\n\n SUM ONCPU (ms):\n", self->count++);
	printa(@oncpu);

	printf("\n   ------\n");
	printf(" SUM ONSYS (ms):\n");
	printa(@onsys);

	trunc(@oncpu, 0);
	trunc(@onsys, 0);
	
	printf("\n Calls:\n");
	printa(@calls);
	trunc(@calls, 0);
}
