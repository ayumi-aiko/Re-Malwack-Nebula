package alya.roshidere.hoshiko
import android.os.Bundle
import android.view.KeyEvent
import android.view.inputmethod.EditorInfo
import android.widget.Toast
import androidx.activity.ComponentActivity
import com.google.android.material.dialog.MaterialAlertDialogBuilder
class MainActivity : ComponentActivity() {
    fun checkRootPrivilages(): Boolean {
        val proc = Runtime.getRuntime().exec(arrayOf("su", "-c", "echo", "Hello root shell!"));
        proc.waitFor();
        if(proc.exitValue() != 0) return false;
        return true;
    }
    fun packageToAdd(packageName: String): Boolean {
        val alyaHandler = Runtime.getRuntime().exec(arrayOf("su", "-c", "/data/adb/Re-Malwack/hoshiko-alya", "--lana-app", "--add-app", packageName));
        alyaHandler.waitFor();
        if(alyaHandler.exitValue() != 0) return false;
        return true;
    }
    fun packageToRemove(packageName: String): Boolean {
        val alyaHandler = Runtime.getRuntime().exec(arrayOf("su", "-c", "/data/adb/Re-Malwack/hoshiko-alya", "--lana-app", "--remove-app", packageName));
        alyaHandler.waitFor();
        if(alyaHandler.exitValue() != 0) return false;
        return true;
    }
    fun manageDaemon(enableDaemon: Boolean): Boolean {
        var argument = "--enable-daemon";
        if(!enableDaemon) argument = "--disable-daemon";
        val alyaHandler = Runtime.getRuntime().exec(arrayOf("su", "-c", "/data/adb/Re-Malwack/hoshiko-alya", "--lana-app", argument));
        alyaHandler.waitFor();
        if(alyaHandler.exitValue() != 0) return false;
        return true;
    }
    fun startDaemonDetached() {
        try {
            Runtime.getRuntime().exec(arrayOf("su", "-c", "nohup", "/data/adb/Re-Malwack/hoshiko-yuki", "&"));
        }
        catch(e: Exception) {
            Toast.makeText(this, "Exception: $e", Toast.LENGTH_SHORT).show();
        }
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        val daemonToggle = findViewById<com.google.android.material.materialswitch.MaterialSwitch>(R.id.enableDaemon);
        val appPackageToAdd = findViewById<com.google.android.material.textfield.TextInputEditText>(R.id.appToAdd);
        val appPackageToRemove = findViewById<com.google.android.material.textfield.TextInputEditText>(R.id.appToRemove);
        val importButton = findViewById<com.google.android.material.button.MaterialButton>(R.id.importPreviousState);
        val exportButton = findViewById<com.google.android.material.button.MaterialButton>(R.id.ExportState);
        if(!checkRootPrivilages()) {
            MaterialAlertDialogBuilder(this).setTitle(getString(R.string.app_name))
                .setMessage(getString(R.string.noroot))
                .setNeutralButton(getString(R.string.okay_button_text)) { dialog, which ->
                    finish();
                }
                .show();
        }
        // by default, disable the daemon and let the user start it again.
        Runtime.getRuntime().exec(arrayOf("su", "-c", "/data/adb/Re-Malwack/hoshiko-alya", "--lana-app", "--kill-daemon"));
        daemonToggle.isChecked = false;
        importButton.setOnClickListener {
            val proc = Runtime.getRuntime().exec(arrayOf("su", "-c", "/data/adb/Re-Malwack/hoshiko-alya", "--lana-app", "--import-package-list", "/sdcard/export-alya.txt"));
            proc.waitFor();
            if(proc.exitValue() != 0) Toast.makeText(this, getString(R.string.failedtoimportpackagelist), Toast.LENGTH_SHORT).show();
            else Toast.makeText(this, getString(R.string.importedpackagelistsuccessfully), Toast.LENGTH_SHORT).show();
        }
        exportButton.setOnClickListener {
            val proc = Runtime.getRuntime().exec(arrayOf("su", "-c", "/data/adb/Re-Malwack/hoshiko-alya", "--lana-app", "--export-package-list", "/sdcard/export-alya.txt"));
            proc.waitFor();
            if(proc.exitValue() != 0) Toast.makeText(this, getString(R.string.failedtoexportpackagelist), Toast.LENGTH_SHORT).show();
            else Toast.makeText(this, getString(R.string.exportedpackagelistsuccessfully), Toast.LENGTH_SHORT).show();
        }
        appPackageToAdd.setOnEditorActionListener { _, actionId, event ->
            if(actionId == EditorInfo.IME_ACTION_DONE || (event != null && event.keyCode == KeyEvent.KEYCODE_ENTER && event.action == KeyEvent.ACTION_DOWN)) {
                val input = appPackageToAdd.text?.toString()?.trim();
                if(!input.isNullOrEmpty()) {
                    return@setOnEditorActionListener if(packageToAdd(input)) {
                        Toast.makeText(this, getString(R.string.addedgivenpackage), Toast.LENGTH_SHORT).show();
                        true;
                    }
                    else {
                        Toast.makeText(this, getString(R.string.failedtoaddgivenpackage), Toast.LENGTH_SHORT).show();
                        false;
                    }
                }
            }
            false;
        }
        appPackageToRemove.setOnEditorActionListener { _, actionId, event ->
            if(actionId == EditorInfo.IME_ACTION_DONE || (event != null && event.keyCode == KeyEvent.KEYCODE_ENTER && event.action == KeyEvent.ACTION_DOWN)) {
                val input = appPackageToRemove.text?.toString()?.trim();
                if(!input.isNullOrEmpty()) {
                    return@setOnEditorActionListener if(packageToRemove(input)) {
                        Toast.makeText(this, getString(R.string.removedgivenpackage), Toast.LENGTH_SHORT).show();
                        true;
                    }
                    else {
                        Toast.makeText(this, getString(R.string.failedtoremovegivenpackage), Toast.LENGTH_SHORT).show();
                        false;
                    }
                }
            }
            false;
        }
        daemonToggle.setOnCheckedChangeListener { buttonView, isChecked ->
            if(isChecked) {
                if(manageDaemon(true)) {
                    buttonView.isChecked = true;
                    Toast.makeText(this, this.getString(R.string.startedyukisuccessfully), Toast.LENGTH_SHORT).show();
                    startDaemonDetached();
                }
                else {
                    buttonView.isChecked = false;
                    Toast.makeText(this, this.getString(R.string.failedtostartyuki), Toast.LENGTH_SHORT).show();
                }
            }
            else {
                if(manageDaemon(false)) {
                    buttonView.isChecked = false;
                    Toast.makeText(this, this.getString(R.string.stoppedyukisuccessfully), Toast.LENGTH_SHORT).show();
                    Runtime.getRuntime().exec(arrayOf("su", "-c", "/data/adb/Re-Malwack/hoshiko-alya", "--lana-app", "--kill-daemon"));
                }
                else {
                    buttonView.isChecked = true;
                    Toast.makeText(this, this.getString(R.string.failedtostopyuki), Toast.LENGTH_SHORT).show();
                }
            }
        }
    }
}