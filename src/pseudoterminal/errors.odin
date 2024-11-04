package pseudoterminal

import "core:os"
import "core:sys/linux"

//---------
// pseudoterminal error types
//---------

Error :: union #shared_nil {
	Setup_Error,
	os.Error,
	linux.Errno,
}

Setup_Error :: enum {
	None = 0,
	Unable_To_Open_Pseudoterminal,	// posix_openpt fail
	Unable_To_Grant_Slave_Access,	// grantpt fail
	Unable_To_Unlock_Slave,			// unlockpt fail
	No_Slave_Name,					// ptsname fail
}
