namespace: flows
flow:
  name: static_scan
  inputs:
    - git_host: github.houston.softwaregrp.net
    - git_organization: stat
    - git_repository: StatPlugin
    - git_branch: master
    - git_source_url: 'https://github.houston.softwaregrp.net/stat/StatPlugin/archive/master.zip'
    - git_token: 574bce08263354945674f7655f206e518b54503b
    - ssh_host: mydtbld0063.hpeswlab.net
    - ssh_host_username: stat
    - ssh_host_password: ''
    - fortify_license_path: /home1/stat/ovidiu/clean_sca/fortify.license
    - fortify_workdir: /home1/stat/ovidiu/clean_sca/test_scan
    - project_source: /home1/stat/ovidiu/project.zip
    - docker_image:
        default: 'security-docker-stat.mydartifactory.swinfra.net/clean-scanner-sca:test'
        required: true
    - ssc_url:
        default: 'http://16.59.65.176:18080/ssc'
        required: false
    - ssc_token:
        default: 6fd14b02-68e5-4e33-9832-a1e7921247df
        required: false
  workflow:
    - check_source__ssh_cmd:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${ssh_host}'
            - command: "${'ls ' + fortify_workdir + '/' + git_repository + '-' + git_branch}"
            - username: '${ssh_host_username}'
            - password:
                value: '${ssh_host_password}'
                sensitive: true
        publish:
          - check_source_output: '${standard_err}'
        navigate:
          - SUCCESS: source_not_exists__string_occurrence
          - FAILURE: on_failure
    - download_source__ssh_cmd:
        do:
          io.cloudslang.base.ssh.ssh_command:
            - host: '${ssh_host}'
            - command: "${'''\nwget \\\n    -O ''' + fortify_workdir + '''/project.zip \\\n    --header=\"Authorization: token '''+ git_token +'''\" \\\n    https://''' + git_host + '/' + git_organization + '/' + git_repository + '/archive/' + git_branch + '''.zip\n\ncd ''' + fortify_workdir + ''' && unzip -o project.zip\ncd ''' + fortify_workdir + ' && rm project.zip'}"
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
            - command: "${'''\nexport SSC_URL=''' + ('\"\"' if ssc_url is None else '\"' + ssc_url + '\"') + '''\nexport SSC_TOKEN=\"''' + ssc_token + '''\"\nexport PROJECT_NAME=\"''' + git_organization + '''\"\nexport VERSION_NAME=\"''' + git_repository + '''\"\n\ndocker run \\\n --rm \\\n --name clean-sca \\\n -e SSC_URL \\\n -e SSC_TOKEN \\\n -e PROJECT_NAME \\\n -e VERSION_NAME \\\n -v ''' + fortify_license_path + ''':/home/fortify/fortify.license \\\n -v ''' + fortify_workdir + ''':/home/fortify/workdir \\\n security-docker-stat.mydartifactory.swinfra.net/clean-scanner-sca:test'''}"
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
            - string_to_find: Scan finished successfully
        navigate:
          - SUCCESS: upload_to_ssc_successful__string_occurrence
          - FAILURE: FAILURE
    - source_not_exists__string_occurrence:
        do:
          io.cloudslang.base.strings.string_occurrence_counter:
            - string_in_which_to_search: '${check_source_output}'
            - string_to_find: No such file or directory
        navigate:
          - SUCCESS: download_source__ssh_cmd
          - FAILURE: start_scan__ssh_cmd
    - upload_to_ssc_successful__string_occurrence:
        do:
          io.cloudslang.base.strings.string_occurrence_counter:
            - string_in_which_to_search: '${output_scan_result}'
            - string_to_find: Upload to SSC was successful
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: SUCCESS
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      check_source__ssh_cmd:
        x: 100
        'y': 250
      download_source__ssh_cmd:
        x: 700
        'y': 125
      start_scan__ssh_cmd:
        x: 700
        'y': 375
      scan_successful__string_occurrence:
        x: 1000
        'y': 250
        navigate:
          55c1ba04-1aba-abff-5950-a07a2cb105d2:
            targetId: 4bb34234-c60a-376f-3c47-f6b4caf60c43
            port: FAILURE
      source_not_exists__string_occurrence:
        x: 400
        'y': 250
      upload_to_ssc_successful__string_occurrence:
        x: 1300
        'y': 125
        navigate:
          eed8aeee-cfbe-b2a2-a073-990d6d17ea8e:
            targetId: c9b0bc64-7a38-ec42-2321-4ccaaf9de904
            port: SUCCESS
            vertices:
              - x: 1506.7858974923242
                'y': 191.89032163585807
              - x: 1536
                'y': 209
          cd4e574b-0fc4-54e6-0d27-d051359147ca:
            targetId: c9b0bc64-7a38-ec42-2321-4ccaaf9de904
            port: FAILURE
            vertices:
              - x: 1451
                'y': 207
              - x: 1491.25
                'y': 228.75
              - x: 1503
                'y': 234
    results:
      FAILURE:
        4bb34234-c60a-376f-3c47-f6b4caf60c43:
          x: 1300
          'y': 375
      SUCCESS:
        c9b0bc64-7a38-ec42-2321-4ccaaf9de904:
          x: 1600
          'y': 250
