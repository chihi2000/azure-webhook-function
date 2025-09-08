this is azure function that gets triggered by github webhook on each push on main brunch.
then this function trigger an azure devops ci/cd pipeline for terraform configs

you can find the configuration of the self hosted agent(azure devops) in /scripts folder.
