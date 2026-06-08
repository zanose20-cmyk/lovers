package com.example.lovers_app

import android.app.Activity
import android.content.Intent
import android.util.Log
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.lovers_app/google_sign_in"
    private val TAG = "GoogleSignInNative"
    private val RC_SIGN_IN = 9001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "signIn" -> {
                    val webClientId = call.argument<String>("webClientId")
                    if (webClientId == null) {
                        result.error("NO_CLIENT_ID", "webClientId is required", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                        .requestIdToken(webClientId)
                        .requestEmail()
                        .build()
                    val client = GoogleSignIn.getClient(this, gso)
                    startActivityForResult(client.signInIntent, RC_SIGN_IN)
                }
                "signInSilently" -> {
                    val webClientId = call.argument<String>("webClientId")
                    if (webClientId == null) {
                        result.error("NO_CLIENT_ID", "webClientId is required", null)
                        return@setMethodCallHandler
                    }
                    val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                        .requestIdToken(webClientId)
                        .requestEmail()
                        .build()
                    val client = GoogleSignIn.getClient(this, gso)
                    client.silentSignIn()
                        .addOnSuccessListener { account -> getIdTokenAndReply(account, result) }
                        .addOnFailureListener { result.success(null) }
                }
                "signOut" -> {
                    GoogleSignIn.getLastSignedInAccount(this)?.let {
                        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN).build()
                        GoogleSignIn.getClient(this, gso).signOut()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == RC_SIGN_IN) {
            if (resultCode == Activity.RESULT_OK) {
                val task = GoogleSignIn.getSignedInAccountFromIntent(data)
                handleSignInTask(task)
            } else {
                pendingResult?.success(null)
                pendingResult = null
            }
        }
    }

    private fun handleSignInTask(task: com.google.android.gms.tasks.Task<GoogleSignInAccount>) {
        try {
            val account = task.getResult(ApiException::class.java)
            getIdTokenAndReply(account, pendingResult)
        } catch (e: ApiException) {
            Log.e(TAG, "Google sign-in failed: " + e.statusCode, e)
            pendingResult?.error("SIGN_IN_FAILED", e.localizedMessage ?: "Sign-in failed", null)
            pendingResult = null
        }
    }

    private fun getIdTokenAndReply(account: GoogleSignInAccount, reply: MethodChannel.Result?) {
        if (reply == null) return
        try {
            val idToken = account.idToken
            if (idToken != null && idToken.isNotEmpty()) {
                reply.success(mapOf("idToken" to idToken))
            } else {
                reply.error("NO_ID_TOKEN", "Google sign-in returned no idToken", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get idToken", e)
            reply.error("AUTH_FAILED", e.message, null)
        }
    }
}
