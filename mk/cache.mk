#
#   Date: Jan 25, 2012
# Author: Eldar Abusalimov
#

ifndef CACHE_INCLUDES
$(error CACHE_INCLUDES is not defined, nothing to cache)
endif
CACHE_USES ?=

ifeq ($(findstring --no-print-directory,$(MAKEFLAGS)),)
$(error '--no-print-directory' flag must be specified)
endif

include mk/core/common.mk

.PHONY : all
all :
	@#

__cache_timestamp := $(shell date)

# Forces certain variables to be dumped unconditionally, even if some of them
# has been already defined before including scripts listed in 'CACHE_INCLUDES'
# (i.e., as part of 'CACHE_USES').
# Usually, volatiles are different counters and lists.
__cache_volatile :=

# Variables listed here are only initialized to an empty string.
# Usually, transients are temporary variables.
__cache_transient :=

__cache_preinclude_variables :=
__cache_postinclude_variables :=

# Include scripts which should not be cached...
include $(CACHE_USES)

# Collect variables...
__cache_preinclude_variables := $(.VARIABLES)
include $(CACHE_INCLUDES)
__cache_postinclude_variables := $(.VARIABLES)

__cache_volatile := $(strip $(__cache_volatile))
__cache_transient := $(strip $(__cache_transient))

# Finally, print everything out.

__cache_new_variables := \
	$(subst %%,%,$(filter-out \
		$(subst %,%%,$(__cache_preinclude_variables)), \
		$(subst %,%%,$(__cache_postinclude_variables))))

# No args.
__cache_print_new_variable_definitions = \
	$(foreach 1,$(call __cache_sort,$(filter-out \
			$(__cache_volatile) $(__cache_transient), \
			$(__cache_new_variables))), \
		$(info $(__cache_construct_variable_definition)))

# No args.
__cache_print_transient_variable_definitions = \
	$(foreach 1,__cache_transient \
		$(call __cache_sort,$(filter \
			$(__cache_transient), \
			$(__cache_new_variables))), \
		$(info $(__cache_construct_variable_definition)))
# No args.
__cache_print_volatile_variable_definitions = \
	$(foreach 1,__cache_volatile \
		$(call __cache_sort,$(__cache_volatile)), \
		$(info $(__cache_construct_variable_definition)))

# Arg 1: list of variables.
__cache_sort = \
	$(foreach v, \
		$(sort $(join $(patsubst [%],%_,$(subst _,,$(1:%=[%]))),$1)),$ \
		$(subst [$v]$(firstword $(subst _,_ ,$v)),,[$v]$v))
#	$(sort $1)# Uncomment for simple lexicographical sort.
#	$1# Or for no sort at all.

# __cache_construct_xxx
# Arg 1: variable name.
__cache_construct_variable_definition = \
	$(__cache_construct_$(if \
		$(findstring $(\h),$(subst $(\n),$(\h),$(value $1))) \
			,verbose,regular)_$(flavor $1)_variable)

__cache_construct_regular_simple_variable = \
	$(__cache_escape_variable_name) := \
		$(if $(__cache_variable_has_leading_ws),$$(\0))$(subst $$,$$$$,$(value $1))

__cache_construct_regular_recursive_variable = \
	$(if $(__cache_variable_has_leading_ws),$ \
		$(__cache_construct_verbose_recursive_variable),$ \
		$(__cache_escape_variable_name) = $(value $1))

__cache_construct_verbose_recursive_variable = \
	define $(__cache_escape_variable_name)$(\n)$ \
		$(value $1)$(\n)$ \
	endef
__cache_construct_verbose_simple_variable = \
	$(__cache_construct_verbose_recursive_variable)$(\n)$ \
	$(__cache_escape_variable_name) := $$(value $(__cache_escape_variable_name))

__cache_construct_regular_undefined_variable = $(__cache_error_undefined)
__cache_construct_verbose_undefined_variable = $(__cache_error_undefined)

__cache_error_undefined = \
	$(error Undefined variable '$1' listed in '.VARIABLES')

__cache_escape_variable_name = \
	$(subst $(=),$$(=),$(subst $(:),$$(:),$(subst $(\h),$$(\h),$(subst $$,$$$$,$1))))
__cache_variable_has_leading_ws = \
	$(subst x$(firstword $(value $1)),,$(firstword x$(value $1)))

__cache_print_uses_inclusions = \
	$(if $(strip $(CACHE_USES)), \
		$(info include $$(filter-out $$(MAKEFILE_LIST),$ \
			$(CACHE_USES:%= \$(\n)$(\t)$(\t)$(\t)%))))

__cache_print_list_comment = \
	$(info $(\h) $1:) \
	$(foreach mk,$(or $($1),<nothing>),$(info $(\h)   $(mk)))

$(info # Generated by GNU Make $(MAKE_VERSION) on $(__cache_timestamp).)
$(info )
$(call __cache_print_list_comment,CACHE_USES)
$(call __cache_print_list_comment,CACHE_INCLUDES)
$(call __cache_print_list_comment,MAKEFILE_LIST)
$(info )
$(info include mk/core/common.mk)
$(__cache_print_uses_inclusions)
$(info )
$(info # Transient variables.)
$(__cache_print_transient_variable_definitions)
$(info )
$(info # Volatiles variables.)
$(__cache_print_volatile_variable_definitions)
$(info )
$(info # New variables.)
$(__cache_print_new_variable_definitions)
$(info )

