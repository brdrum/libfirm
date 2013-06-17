$arch = "amd64";

%reg_classes = (
	gp => [
		{ name => "rax", dwarf => 0 },
		{ name => "rcx", dwarf => 2 },
		{ name => "rdx", dwarf => 1 },
		{ name => "rsi", dwarf => 4 },
		{ name => "rdi", dwarf => 5 },
		{ name => "rbx", dwarf => 3 },
		{ name => "rbp", dwarf => 6 },
		{ name => "rsp", dwarf => 7 },
		{ name => "r8",  dwarf => 8 },
		{ name => "r9",  dwarf => 9 },
		{ name => "r10", dwarf => 10 },
		{ name => "r11", dwarf => 11 },
		{ name => "r12", dwarf => 12 },
		{ name => "r13", dwarf => 13 },
		{ name => "r14", dwarf => 14 },
		{ name => "r15", dwarf => 15 },
		{ mode => "mode_Lu" }
	],
	flags => [
		{ name => "eflags", dwarf => 49 },
		{ mode => "mode_Iu", flags => "manual_ra" }
	],
);

$mode_gp        = "mode_Lu";
$mode_flags     = "mode_Iu";

sub amd64_custom_init_attr {
	my $constr = shift;
	my $node   = shift;
	my $name   = shift;
	my $res    = "";

	if(defined($node->{modified_flags})) {
		$res .= "\tarch_add_irn_flags(res, arch_irn_flag_modify_flags);\n";
	}
	return $res;
}
$custom_init_attr_func = \&amd64_custom_init_attr;

$default_copy_attr = "amd64_copy_attr";

%init_attr = (
	amd64_attr_t           =>
		 "\tinit_amd64_attributes(res, irn_flags_, in_reqs, n_res);",
	amd64_SymConst_attr_t =>
		"\tinit_amd64_attributes(res, irn_flags_, in_reqs, n_res);"
		. "\tinit_amd64_SymConst_attributes(res, entity);",
	amd64_switch_jmp_attr_t =>
		"\tinit_amd64_attributes(res, irn_flags_, in_reqs, n_res);"
		. "\tinit_amd64_switch_attributes(res, table, table_entity);"
);

%compare_attr = (
	amd64_attr_t             => "cmp_amd64_attr",
	amd64_SymConst_attr_t    => "cmp_amd64_attr_SymConst",
	amd64_switch_jmp_attr_t  => "cmp_amd64_attr",
);

%nodes = (
PushAM => {
	op_flags  => [ "uses_memory" ],
	state     => "exc_pinned",
	reg_req   => { in => [ "gp", "none", "rsp" ], out => [ "rsp:I|S", "none" ] },
	ins       => [ "base", "mem", "stack" ],
	outs      => [ "stack", "M" ],
	attr      => "amd64_insn_mode_t insn_mode, int64_t offset, ir_entity *symconst",
	init_attr => "attr->imm.offset     = offset;\n"
	           . "attr->imm.symconst   = symconst;\n"
	           . "attr->data.insn_mode = insn_mode;\n",
	emit      => "push %AM",
},

PopAM => {
	op_flags  => [ "uses_memory" ],
	state     => "exc_pinned",
	reg_req   => { in => [ "gp", "none", "rsp" ], out => [ "rsp:I|S", "none" ] },
	ins       => [ "base", "mem", "stack" ],
	outs      => [ "stack", "M" ],
	attr      => "amd64_insn_mode_t insn_mode, int64_t offset, ir_entity *symconst",
	init_attr => "attr->imm.offset     = offset;\n"
	           . "attr->imm.symconst   = symconst;\n"
	           . "attr->data.insn_mode = insn_mode;\n",
	emit      => "pop %AM",
},

Add => {
	irn_flags  => [ "rematerializable" ],
	state      => "exc_pinned",
	attr       => "amd64_insn_mode_t insn_mode",
	init_attr  => "attr->data.insn_mode = insn_mode;",
	reg_req    => { in => [ "gp", "gp" ], out => [ "in_r1 !in_r2" ] },
	ins        => [ "left", "right" ],
	outs       => [ "res" ],
	emit       => "add%M %S1, %D0",
	mode       => $mode_gp,
	modified_flags => 1,
},

And => {
	irn_flags  => [ "rematerializable" ],
	state      => "exc_pinned",
	attr       => "amd64_insn_mode_t insn_mode",
	init_attr  => "attr->data.insn_mode = insn_mode;",
	reg_req    => { in => [ "gp", "gp" ], out => [ "in_r1 !in_r2" ] },
	ins        => [ "left", "right" ],
	outs       => [ "res" ],
	emit       => "and%M %S1, %D0",
	mode       => $mode_gp,
	modified_flags => 1,
},

Div => {
	irn_flags  => [ "rematerializable" ],
	state      => "exc_pinned",
	attr       => "amd64_insn_mode_t insn_mode",
	init_attr  => "attr->data.insn_mode = insn_mode;",
	reg_req    => { in => [ "rdx", "rax", "gp", "none" ], out => [ "rax", "rdx", "none" ] },
	ins        => [ "left_high", "left_low", "right", "mem" ],
	outs       => [ "res_div", "res_mod", "M" ],
	emit       => "div%M %S2",
	modified_flags => 1,
},

IDiv => {
	irn_flags  => [ "rematerializable" ],
	state      => "exc_pinned",
	attr       => "amd64_insn_mode_t insn_mode",
	init_attr  => "attr->data.insn_mode = insn_mode;",
	reg_req    => { in => [ "rdx", "rax", "gp", "none" ], out => [ "rax", "rdx", "none" ] },
	ins        => [ "left_high", "left_low", "right", "mem" ],
	outs       => [ "res_div", "res_mod", "M" ],
	emit       => "idiv%M %S2",
	modified_flags => 1,
},

IMul => {
	irn_flags => [ "rematerializable" ],
	state     => "exc_pinned",
	attr      => "amd64_insn_mode_t insn_mode",
	init_attr => "attr->data.insn_mode = insn_mode;",
	reg_req   => { in  => [ "gp", "gp" ], out => [ "in_r1 !in_r2" ] },
	ins       => [ "left", "right" ],
	outs      => [ "res" ],
	emit      => "imul%M %S1, %D0",
	mode      => $mode_gp,
	am        => "source,binary",
	modified_flags => $status_flags
},

Or => {
	irn_flags  => [ "rematerializable" ],
	state      => "exc_pinned",
	attr       => "amd64_insn_mode_t insn_mode",
	init_attr  => "attr->data.insn_mode = insn_mode;",
	reg_req    => { in => [ "gp", "gp" ], out => [ "in_r1 !in_r2" ] },
	ins        => [ "left", "right" ],
	outs       => [ "res" ],
	emit       => "or%M %S1, %D0",
	mode       => $mode_gp,
	modified_flags => 1,
},

Shl => {
	irn_flags => [ "rematerializable" ],
	attr      => "amd64_insn_mode_t insn_mode",
	init_attr => "attr->data.insn_mode = insn_mode;",
	reg_req   => { in => [ "gp", "rcx" ], out => [ "in_r1 !in_r2" ] },
	ins       => [ "val", "count" ],
	out       => [ "res" ],
	emit      => "shl%M %%cl, %D0",
	mode      => $mode_gp,
	modified_flags => $status_flags
},

Shr => {
	irn_flags => [ "rematerializable" ],
	attr      => "amd64_insn_mode_t insn_mode",
	init_attr => "attr->data.insn_mode = insn_mode;",
	reg_req   => { in => [ "gp", "rcx" ], out => [ "in_r1 !in_r2" ] },
	ins       => [ "val", "count" ],
	out       => [ "res" ],
	emit      => "shr%M %%cl, %D0",
	mode      => $mode_gp,
	modified_flags => $status_flags
},

Sar => {
	irn_flags => [ "rematerializable" ],
	attr      => "amd64_insn_mode_t insn_mode",
	init_attr => "attr->data.insn_mode = insn_mode;",
	reg_req   => { in => [ "gp", "rcx" ], out => [ "in_r1 !in_r2" ] },
	ins       => [ "val", "count" ],
	out       => [ "res" ],
	emit      => "sar%M %%cl, %D0",
	mode      => $mode_gp,
	modified_flags => $status_flags
},

Sub => {
	irn_flags  => [ "rematerializable" ],
	attr       => "amd64_insn_mode_t insn_mode",
	init_attr  => "attr->data.insn_mode = insn_mode;",
	state      => "exc_pinned",
	reg_req    => { in => [ "gp", "gp" ], out => [ "in_r1 !in_r2" ] },
	ins        => [ "left", "right" ],
	outs       => [ "res" ],
	emit       => "sub%M %S1, %D0",
	mode       => $mode_gp,
	modified_flags => 1,
},

Neg => {
	irn_flags => [ "rematerializable" ],
	attr      => "amd64_insn_mode_t insn_mode",
	init_attr => "attr->data.insn_mode = insn_mode;",
	reg_req   => { in => [ "gp" ],
	               out => [ "in_r1" ] },
	emit      => "neg%M %S0",
	ins       => [ "val" ],
	outs      => [ "res" ],
	mode      => $mode_gp,
	modified_flags => $status_flags
},

Not => {
	irn_flags => [ "rematerializable" ],
	attr      => "amd64_insn_mode_t insn_mode",
	init_attr => "attr->data.insn_mode = insn_mode;",
	reg_req   => { in => [ "gp" ], out => [ "in_r1" ] },
	emit      => "not%M %S0",
	ins       => [ "val" ],
	outs      => [ "res" ],
	mode      => $mode_gp,
	modified_flags => $status_flags
},

Xor => {
	irn_flags  => [ "rematerializable" ],
	attr       => "amd64_insn_mode_t insn_mode",
	init_attr  => "attr->data.insn_mode = insn_mode;",
	state      => "exc_pinned",
	reg_req    => { in => [ "gp", "gp" ], out => [ "in_r1 !in_r2" ] },
	ins        => [ "left", "right" ],
	outs       => [ "res" ],
	emit       => "xor%M %S1, %D0",
	mode       => $mode_gp,
	modified_flags => 1,
},

Xor0 => {
	op_flags   => [ "constlike" ],
	irn_flags  => [ "rematerializable" ],
	init_attr  => "attr->data.insn_mode = INSN_MODE_32;",
	reg_req    => { out => [ "gp" ] },
	outs       => [ "res" ],
	emit       => "xorl %D0, %D0",
	mode       => $mode_gp,
	modified_flags => 1,
},

Const => {
	op_flags  => [ "constlike" ],
	attr      => "amd64_insn_mode_t insn_mode, int64_t offset, ir_entity *symconst",
	init_attr => "attr->imm.offset     = offset;\n"
	           . "attr->imm.symconst   = symconst;\n"
	           . "attr->data.insn_mode = insn_mode;\n",
	reg_req   => { out => [ "gp" ] },
	emit      => 'mov%M $%C, %D0',
	mode      => $mode_gp,
},

Conv => {
	state     => "exc_pinned",
	attr      => "ir_mode *smaller_mode",
	init_attr => "attr->ls_mode = smaller_mode;",
	reg_req   => { in => [ "gp" ], out => [ "gp" ] },
	ins       => [ "val" ],
	outs      => [ "res" ],
	emit      => "mov%c%M %#S0, %D0",
	mode      => $mode_gp,
},

Jmp => {
	state     => "pinned",
	op_flags  => [ "cfopcode" ],
	reg_req   => { out => [ "none" ] },
	mode      => "mode_X",
},

Cmp => {
	irn_flags => [ "rematerializable" ],
	state     => "exc_pinned",
	reg_req   => { in  => [ "gp", "gp" ],
	               out => [ "flags" ] },
	ins       => [ "left", "right" ],
	outs      => [ "eflags" ],
	emit      => "cmp%M %S1, %S0",
	attr      => "amd64_insn_mode_t insn_mode, int ins_permuted, int cmp_unsigned",
	init_attr => "attr->data.ins_permuted   = ins_permuted;\n".
	             "\tattr->data.cmp_unsigned = cmp_unsigned;\n".
	             "\tattr->data.insn_mode    = insn_mode;\n",
	mode      => $mode_flags,
	modified_flags => 1,
},

Jcc => {
	state     => "pinned",
	op_flags  => [ "cfopcode", "forking" ],
	reg_req   => { in  => [ "eflags" ], out => [ "none", "none" ] },
	ins       => [ "eflags" ],
	outs      => [ "false", "true" ],
	attr      => "ir_relation relation",
	init_attr => "attr->ext.relation = relation;",
	mode      => "mode_T",
},

LoadZ => {
	op_flags  => [ "uses_memory" ],
	state     => "exc_pinned",
	reg_req   => { in => [ "gp", "none" ],
	               out => [ "gp", "none" ] },
	ins       => [ "ptr", "mem" ],
	outs      => [ "res",  "M" ],
	attr      => "amd64_insn_mode_t insn_mode, ir_entity *entity",
	attr_type => "amd64_SymConst_attr_t",
	init_attr => "attr->base.data.insn_mode = insn_mode;",
	emit      => "mov%M %O(%^S0), %D0"
},

LoadS => {
	op_flags  => [ "uses_memory" ],
	state     => "exc_pinned",
	reg_req   => { in => [ "gp", "none" ],
	               out => [ "gp", "none" ] },
	ins       => [ "ptr", "mem" ],
	outs      => [ "res",  "M" ],
	attr      => "amd64_insn_mode_t insn_mode, ir_entity *entity",
	attr_type => "amd64_SymConst_attr_t",
	init_attr => "attr->base.data.insn_mode = insn_mode;",
	emit      => "movs%Mq %O(%^S0), %^D0"
},

FrameAddr => {
	op_flags  => [ "constlike" ],
	irn_flags => [ "rematerializable" ],
	reg_req   => { in => [ "gp" ], out => [ "gp" ] },
	ins       => [ "base" ],
	attr      => "ir_entity *entity",
	attr_type => "amd64_SymConst_attr_t",
	mode      => $mode_gp,
},

Store => {
	op_flags  => [ "uses_memory" ],
	state     => "exc_pinned",
	reg_req   => { in => [ "gp", "gp", "none" ], out => [ "none" ] },
	ins       => [ "ptr", "val", "mem" ],
	outs      => [ "M" ],
	attr      => "amd64_insn_mode_t insn_mode, ir_entity *entity",
	attr_type => "amd64_SymConst_attr_t",
	init_attr => "attr->base.data.insn_mode = insn_mode;",
	mode      => "mode_M",
	emit      => "mov%M %S1, %O(%^S0)"
},

SwitchJmp => {
	op_flags     => [ "cfopcode", "forking" ],
	state        => "pinned",
	mode         => "mode_T",
	reg_req      => { in => [ "gp" ], out => [ "none" ] },
	out_arity    => "variable",
	attr_type    => "amd64_switch_jmp_attr_t",
	attr         => "const ir_switch_table *table, ir_entity *table_entity",
},

Call => {
	state     => "exc_pinned",
	arity     => "variable",
	out_arity => "variable",
},

Start => {
	state     => "pinned",
	out_arity => "variable",
	ins       => [],
},

Return => {
	state  => "pinned",
	op_flags => [ "cfopcode" ],
	arity    => "variable",
	reg_req  => { out => [ "none" ] },
	mode     => "mode_X",
},

);
