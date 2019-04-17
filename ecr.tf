/* Store docker images.
 */

resource "aws_ecr_repository" "backend" {
  name = "backend"
}
