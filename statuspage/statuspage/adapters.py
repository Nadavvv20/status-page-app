import os
from allauth.socialaccount.adapter import DefaultSocialAccountAdapter
from django.core.exceptions import PermissionDenied

class MyGitHubAdapter(DefaultSocialAccountAdapter):
    def pre_social_login(self, request, sociallogin):
        # Extract the GitHub username
        github_username = sociallogin.account.extra_data.get('login')
        
        # Read allowed users from environment variable
        allowed_users_env = os.environ.get('ALLOWED_GITHUB_USERS', '')
        allowed_users = [user.strip() for user in allowed_users_env.split(',') if user.strip()]
        
        # Check if the user is in the allowed list
        if github_username not in allowed_users:
            raise PermissionDenied(f"GitHub user '{github_username}' is not allowed to log in.")
