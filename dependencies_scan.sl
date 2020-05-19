namespace: flows
flow:
  name: dependency_scan
  inputs:
    - artifactory_host: mydartifactory.swinfra.net
    - artifactory_api_token: 'AKCp5dKPWRyS3iCzejvi7VUWzrjwhvwzvbQHVTbirQqNSccRqLVgYUqu1XpdHLJr78SRPAHp2"'
    - ssh_host: mydtbld0063.hpeswlab.net
    - ssh_host_username: stat
    - ssh_host_password: ''
    - scan_workdir: /home1/stat/ovidiu/clean_dependency_scan/testscan/
    - scan_project_name: TEST_PROJECT
    - scan_version_name: TEST_VERSION
    - docker_image:
        default: '/clean-scanner-dependency:test'
        required: true
  workflow:
    - download_artifactory_items__ssh_cmd:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${ssh_host}'
            - command: "${'''\ninput=\"''' + scan_workdir + '''/artifactory_list.txt\"\nmkdir -p \"''' + scan_workdir + '''/artifactory\"\nwhile IFS= read -r line\ndo\n  echo \"$line\"\n  # download all missing files (i.e. if a file with the same name already exists, it will not be re-downloaded)\n  wget \\\n        -nc \\\n        --directory-prefix=\"''' + scan_workdir + '''/artifactory\" \\\n        --header=\"X-JFrog-Art-Api: ''' + artifactory_api_token + '''\" \\\n        https://''' + artifactory_host + '''/artifactory/${line}\ndone < \"$input\"\n'''}"
            - username: '${ssh_host_username}'
            - password:
                value: '${ssh_host_password}'
                sensitive: true
        navigate:
          - SUCCESS: start_scan__ssh_cmd
          - FAILURE: on_failure
    - start_scan__ssh_cmd:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${ssh_host}'
            - command: "${'''\nexport PROJECT_NAME=\"''' + scan_project_name + '''\"\nexport VERSION_NAME=\"''' + scan_version_name + '''\"\n\ndocker run \\\n --rm \\\n --name clean-dependency-scan \\\n -e PROJECT_NAME \\\n -e VERSION_NAME \\\n -v ''' + scan_workdir + ''':/home/scanner/workdir \\\n security-docker-stat.mydartifactory.swinfra.net/clean-scanner-dependency:test'''}"
            - username: '${ssh_host_username}'
            - password:
                value: '${ssh_host_password}'
                sensitive: true
            - timeout: '1000000'
        publish:
          - output_scan_result: '${standard_out}'
        navigate:
          - SUCCESS: scan_successful__string_occurrence
          - FAILURE: on_failure
    - scan_successful__string_occurrence:
        do:
          io.cloudslang.base.strings.string_occurrence_counter:
            - string_in_which_to_search: '${output_scan_result}'
            - string_to_find: '[INFO] Analysis Complete'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      download_artifactory_items__ssh_cmd:
        x: 100
        'y': 250
      start_scan__ssh_cmd:
        x: 400
        'y': 250
      scan_successful__string_occurrence:
        x: 700
        'y': 250
        navigate:
          ff3b23aa-6fe7-2c61-ad8e-a10768352c62:
            targetId: 4c7999a1-1fa5-7bc7-50a9-7e985a1b8cce
            port: SUCCESS
          5b8e208a-a48f-08cf-0575-bb17f3a3ca3a:
            targetId: e9532fea-e5c3-5f0f-5398-ba29c229234d
            port: FAILURE
    results:
      FAILURE:
        e9532fea-e5c3-5f0f-5398-ba29c229234d:
          x: 1000
          'y': 375
      SUCCESS:
        4c7999a1-1fa5-7bc7-50a9-7e985a1b8cce:
          x: 1000
          'y': 125
