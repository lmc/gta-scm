# called as a gosub before the save menu is shown
[:labeldef, :save_thread_ext]
log("scripts terming")

# kill scripts that will have PCs in undefined code if scm file is uninstalled
terminate_all_scripts_with_this_name("xextldr")
terminate_all_scripts_with_this_name("xhelper")

$code_state = 0
$save_in_progress = 1

# wait to make sure threads are dead
wait(260)

# jump back to destination of original save menu gosub we patched
[:goto, [[:int32,88389]]]



# called as gosub after the save menu is shown
[:labeldef,:save_thread_after_ext]

$save_in_progress = 0
# jump back to destination of original save menu gosub we patched
[:goto, [[:int32,88469]]]

