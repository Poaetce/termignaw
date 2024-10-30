package pseudoterminal

import "core:os"
import "core:sys/linux"

Error :: union #shared_nil {
	Setup_Error,
	os.Error,
	linux.Errno,
}

Setup_Error :: enum {
	None = 0,
	Unable_To_Open_Pseudoterminal,
	Unable_To_Grant_Slave_Access,
	Unable_To_Unlock_Slave,
	No_Slave_Name,
}
