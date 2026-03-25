# TODO(tyler): Some of these paths might not be necessary, especially when
#  moving to venv.  

# --> maybe not this though?
export PATH=/opt/local/lib/postgresql91/bin/:$PATH

# --> especially this django_dir
export django_dir=/opt/local/Library/Frameworks/Python.framework/Versions/2.6/lib/python2.6/site-packages/django


eval "$(/opt/homebrew/bin/brew shellenv)"
