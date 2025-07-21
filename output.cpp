#include "output.h"
#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include <cstring>
#include <vector>
#include <ctime>
#include <cstdlib>

using namespace std;

void print_structure(atom *list, vector<int> Als, int struc, string name_zeo, string name_alg, string out_name) {
	
	int alcount, ctl;
	string fname, s;
	ofstream fout;

	fname = out_name + "/" + name_zeo + "_" + name_alg + "_" + to_string(struc) + ".cif";

    fout.open(fname.c_str());    
    if(fout.fail()) {
        cerr << "unable to open file " << fname.c_str() << " for writing" << endl;
        exit( 1 );
    }

	fout << setprecision(3) << fixed;

	// Get current date
	time_t rawtime;
	struct tm * timeinfo;
	char date_buffer[80];
	time(&rawtime);
	timeinfo = localtime(&rawtime);
	strftime(date_buffer, sizeof(date_buffer), "%Y-%m-%d", timeinfo);
	
	// Get current user name
	const char* username = getenv("USER");
	if (username == nullptr) {
		username = getenv("USERNAME"); // Windows fallback
		if (username == nullptr) {
			username = "unknown_user";
		}
	}

	fout << "data_" << name_zeo << endl << endl;

	fout << "_audit_creation_method RASPA-1.0" << endl;
	fout << "_audit_creation_date " << date_buffer << endl;
	fout << "_audit_author_name '" << username << "'" << endl << endl;

	fout << "_cell_length_a    " << a << endl;
	fout << "_cell_length_b    " << b << endl;
	fout << "_cell_length_c    " << c << endl;
	fout << "_cell_angle_alpha " << alpha << endl;
	fout << "_cell_angle_beta  " << beta << endl;
	fout << "_cell_angle_gamma " << gama << endl;
	fout << "_cell_volume      " << a*b*c << endl << endl;

	fout << "_symmetry_cell_setting          " << setting << endl;
	fout << "_symmetry_space_group_name_Hall 'P 1'" << endl;
	fout << "_symmetry_space_group_name_H-M  'P 1'" << endl;
	fout << "_symmetry_Int_Tables_number     1" << endl;

	fout << "_symmetry_equiv_pos_as_xyz 'x,y,z'" << endl << endl;

	fout << "loop_" << endl;
	fout << "_atom_site_label" << endl;
	fout << "_atom_site_type_symbol" << endl;
	fout << "_atom_site_fract_x" << endl;
	fout << "_atom_site_fract_y" << endl;
	fout << "_atom_site_fract_z" << endl;
	fout << "_atom_site_charge" << endl;

	alcount=1;

	int Tat=-1;
	for(int i=0; i<Natoms; i++) {
		if(strcmp(list[i].id,"Si") ==0 ) {
			Tat++;
			ctl=1;
			for(unsigned int j=0; j<Als.size() && ctl==1; j++) {
				if(Tat == Als[j]) {
					//Put Al
					fout << "Al" << alcount << "        Al     " << list[i].x << setw(10) << list[i].y << setw(10) << list[i].z << setw(10) << list[i].q << endl;  
					ctl=0;
					alcount++;
				}
			}
			//Put Si
			if(ctl == 1) {
				fout << list[i].at << setw(10) << list[i].id << setw(10) << list[i].x << setw(10) << list[i].y << setw(10) << list[i].z << setw(10) << list[i].q << endl;
			}
		} else {
			fout << list[i].at << setw(10) << list[i].id << setw(10) << list[i].x << setw(10) << list[i].y << setw(10) << list[i].z << setw(10) << list[i].q << endl;
		}
	}

	fout.close();
	return;
}
