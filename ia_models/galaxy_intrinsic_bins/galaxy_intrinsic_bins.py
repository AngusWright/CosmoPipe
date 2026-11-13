from cosmosis.datablock import names, option_section

"""
This module generalises the do_galaxy_intrinsic step of the linear_alignments_interface.py 
for an arbitrary number of bins:
    P_gI = P_GI * p_gm / p_nl
reads: matter_galaxy_power_<i>
writes: galaxy_intrinsic_power_<i>
It also handles the standard (unbinned) case in the same way as the linear_alignment_interface.py does.
"""

def setup(options):
    name = options.get_string(option_section, "name", default="").lower()
    if name:
        suffix = "_" + name
    else:
        suffix = ""

    return suffix

def execute(block, config):
    suffix = config

    nl = names.matter_power_nl
    ia_gi = names.galaxy_intrinsic_power + suffix
    ia_mi = names.matter_intrinsic_power + suffix
    gm = "matter_galaxy_power" + suffix

    z_nl, k_nl, p_nl = block.get_grid(nl, "z", "k_h", "p_k")

    # read P_GI from the datablock (written by the linear alignments module)
    z_I, k_I, P_GI = block.get_grid(ia_mi, "z", "k_h", "p_k")

    # Copied the code inside the "if gal_intrinsic_power" block in linear_alignment_interface.py
    # Loop through all matter_galaxy_power_<i> bins.
    i = 1
    while block.has_section(gm + f"_{i}"):
        z, k, p_gm = block.get_grid(gm + f"_{i}", "z", "k_h", "p_k")
        P_gI = P_GI * p_gm / p_nl
        block.put_grid(ia_gi + f"_{i}", "z", z, "k_h", k, "p_k", P_gI)
        i += 1

    # If the datablock only contains a matter_galaxy_power section (without bin suffix) do exactly what the linear alignments module does
    if block.has_section(gm):
        z, k, p_gm = block.get_grid(gm, "z", "k_h", "p_k")
        P_gI = P_GI * p_gm / p_nl
        block.put_grid(ia_gi, "z", z, "k_h", k, "p_k", P_gI)

    # Raise an error if matter_galaxy_power section is not present in the datablock
    if i == 1 and not block.has_section(gm):
        raise ValueError(f"Datablock does not contain any {gm} section")

    return 0

def cleanup(config):
    pass