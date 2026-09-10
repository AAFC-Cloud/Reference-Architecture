locals {
  people_with_descriptors = [
    for person in local.people : merge(person, {
      descriptor = tolist(data.azuredevops_users.main["${person.origin}:${person.origin_id}"].users)[0].descriptor
    })
  ]
}
