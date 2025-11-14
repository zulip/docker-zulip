# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

import os

import yaml

script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

with open("../compose.yaml", "r") as compose_file:
    compose_data = yaml.safe_load(compose_file)
with open("../kubernetes/chart/zulip/Chart.yaml", "r") as chart_file:
    chart_data = yaml.safe_load(chart_file)

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = "docker-zulip"
copyright = "2025, Kandra Labs, Inc., and contributors"
author = "The Zulip Team"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.intersphinx",
    "myst_parser",
    "sphinx_rtd_theme",
]

templates_path = ["_templates"]
exclude_patterns = ["_build"]
pygments_style = "sphinx"

myst_enable_extensions = [
    "colon_fence",
    "substitution",
    "fieldlist",
]

myst_heading_anchors = 6
myst_substitutions = {
    "DOCKER_VERSION": compose_data["services"]["zulip"]["image"].split(":")[1],
    "HELM_VERSION": chart_data["version"],
}

intersphinx_mapping = {
    "zulip": ("https://zulip.readthedocs.io/en/latest", None),
}
intersphinx_disabled_reftypes = ["*"]

# Link-checking
linkcheck_ignore = [r"https://chat.zulip.org/#"]

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "sphinx_rtd_theme"
html_theme_options = {
    #    "collapse_navigation": not on_rtd,  # makes local builds much faster
    "logo_only": True,
}
html_logo = "_static/images/zulip-logo.svg"
html_static_path = ["_static"]
