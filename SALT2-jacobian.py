import argparse

def get_args():
    parser = argparse.ArgumentParser(description='Approximate SALT2 surfaces with a jacobian')
    parser.add_argument('input', type=str, help="Input toml file to control SALT2-jacobian")
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = get_args()
