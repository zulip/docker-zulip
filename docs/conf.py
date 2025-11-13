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
with open("../helm/zulip/Chart.yaml", "r") as chart_file:
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
    "sphinx.ext.autosectionlabel",
    "myst_parser",
    "sphinx_copybutton",
    "sphinx_rtd_theme",
]

templates_path = ["_templates"]
exclude_patterns = ["_build", ".venv"]
pygments_style = "sphinx"

myst_enable_extensions = [
    "colon_fence",
    "substitution",
    "fieldlist",
]

autosectionlabel_prefix_document = True
autosectionlabel_maxdepth = 2

myst_heading_anchors = 6

copybutton_exclude = ".linenos, .gp"

docker_image = compose_data["services"]["zulip"]["image"].split(":")[1]
zulip_version = docker_image.split("-")[0]


myst_url_schemes = {
    "http": None,
    "https": None,
    "zulip-repo": f"https://github.com/zulip/zulip/blob/{zulip_version}/" + "{{path}}",
    "zulip-repo-raw": f"https://raw.githubusercontent.com/zulip/zulip/refs/tags/{zulip_version}/"
    + "{{path}}",
}


myst_substitutions = {
    "ZULIP_VERSION": zulip_version,
    "DOCKER_VERSION": compose_data["services"]["zulip"]["image"].split(":")[1],
    "HELM_VERSION": chart_data["version"],
}

intersphinx_mapping = {
    "zulip": (f"https://zulip.readthedocs.io/en/{zulip_version}", None),
}
intersphinx_disabled_reftypes = ["*"]

# Link-checking
linkcheck_ignore = [r"https://chat.zulip.org/#"]

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "sphinx_rtd_theme"
html_theme_options = {
    "logo_only": True,
}
html_logo = "_static/images/zulip-logo.svg"
html_static_path = ["_static"]
